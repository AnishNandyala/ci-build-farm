# Dockerfile
FROM python:latest

# Install AWS SDK and any other deps
RUN pip install boto3

# Set working dir, copy your agent code in
WORKDIR /app
COPY . /app

# Default command to start your agent
CMD ["python", "process_job.py"]