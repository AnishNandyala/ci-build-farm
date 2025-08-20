# Use a slim Python base
FROM python:3.9-slim

# Install git (for cloning repos) and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

# Create and switch to app directory
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the job processor script
COPY process_job.py .

# Set the entrypoint to run the processor
ENTRYPOINT ["python3", "process_job.py"]
