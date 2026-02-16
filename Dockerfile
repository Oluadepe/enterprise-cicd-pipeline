FROM python:3.12-slim

WORKDIR /app
COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app /app
EXPOSE 8080

# Security hardening (basic):
RUN useradd -m appuser
USER appuser

CMD ["python", "app.py"]
