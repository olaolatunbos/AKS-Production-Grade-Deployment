FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN groupadd --system appgroup && useradd --system --gid appgroup appuser
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["python", "-m", "http.server", "3000"]