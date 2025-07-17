from flask import Flask, render_template, request, send_file
import os
import pandas as pd
import pdfplumber
import io
import re
from openai import OpenAI

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

CATEGORIES = [
    "Groceries", "Entertainment", "Transport", "Rent", "Salary",
    "Utilities", "Shopping", "Food & Drink", "Other"
]

# Store DataFrames in memory for download
last_transactions_df = None
last_summary_df = None

@app.route('/', methods=['GET', 'POST'])
def index():
    global last_transactions_df, last_summary_df
    summary = None

    if request.method == 'POST':
        uploaded_file = request.files.get('statement')
        if uploaded_file and uploaded_file.filename.endswith('.pdf'):
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], uploaded_file.filename)
            uploaded_file.save(filepath)

            df = extract_lloyds_transactions(filepath)
            df['Category'] = df['Details'].apply(categorize_with_gpt)
            df['Money Out (£)'] = pd.to_numeric(df['Money Out (£)'], errors='coerce').fillna(0)

            summary_df = df.groupby('Category')['Money Out (£)'].sum().reset_index()
            summary = summary_df.to_dict(orient='records')

            # Store for download
            last_transactions_df = df
            last_summary_df = summary_df

            return render_template("index.html", summary=summary)

        else:
            return "Only PDF files are supported.", 400

    return render_template("index.html", summary=summary)

@app.route('/download')
def download_excel():
    global last_transactions_df, last_summary_df

    if last_transactions_df is None or last_summary_df is None:
        return "No data to export. Please upload a file first.", 400

    output = io.BytesIO()
    with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
        last_transactions_df.to_excel(writer, index=False, sheet_name='Transactions')
        last_summary_df.to_excel(writer, index=False, sheet_name='Summary')

    output.seek(0)
    return send_file(output, download_name='categorized_statement.xlsx', as_attachment=True)


def extract_lloyds_transactions(filepath):
    transactions = []
    pattern = re.compile(
        r'(?P<date>\d{2}[A-Za-z]{3}\d{2})\s+'
        r'(?P<type>[A-Z]{2,4})\s+'
        r'(?P<details>.+?)\s+'
        r'(?P<amount1>\d+\.\d{2})\s+'
        r'(?:(?P<amount2>\d+\.\d{2})\s+)?'
        r'(?P<balance>\d+\.\d{2})'
    )

    with pdfplumber.open(filepath) as pdf:
        text = "\n".join(page.extract_text() for page in pdf.pages if page.extract_text())

    for line in text.split('\n'):
        match = pattern.search(line)
        if match:
            data = match.groupdict()
            txn_type = data['type']
            money_out = None
            money_in = None

            if txn_type in ['TFR', 'FPO', 'FPI']:
                money_in = data['amount1']
            elif txn_type in ['DEB', 'DD']:
                money_out = data['amount1']
            else:
                money_out = data['amount1']
                if data['amount2']:
                    money_in = data['amount2']

            transactions.append({
                'Date': data['date'],
                'Type': txn_type,
                'Details': data['details'].strip(),
                'Money Out (£)': money_out,
                'Money In (£)': money_in,
                'Balance (£)': data['balance']
            })

    return pd.DataFrame(transactions)

def categorize_with_gpt(description):
    prompt = (
        f"Categorize this bank transaction description into one of these categories, if you cannot categorise choose Other:\n"
        f"{', '.join(CATEGORIES)}.\n"
        f"Transaction: {description}\n"
        f"Category:"
    )
    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful financial assistant that categorizes bank transactions."},
                {"role": "user", "content": prompt}
            ],
            temperature=0
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"OpenAI error: {e}")
        return "Uncategorized"

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=3000)
