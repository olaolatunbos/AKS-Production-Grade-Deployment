FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Change ownership of the /app directory to the non-root user
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose the port Flask runs on
EXPOSE 3000

# Run the Flask app
CMD ["python3", "app.py"]