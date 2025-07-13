#!/usr/bin/env python3
import os
import time
import json
import shutil
import uuid
import boto3
import subprocess

# ── Configuration from environment ──────────────────────────────────────
QUEUE_URL       = os.environ["QUEUE_URL"]
ARTIFACTS_BUCKET = os.environ["ARTIFACTS_BUCKET"]
AWS_REGION      = os.environ.get("AWS_REGION", "us-east-1")
POLL_INTERVAL   = int(os.environ.get("POLL_INTERVAL", "5"))

sqs = boto3.client("sqs", region_name=AWS_REGION)
s3  = boto3.client("s3", region_name=AWS_REGION)

def process_message(body):
    job = json.loads(body)
    job_id    = job.get("id", str(uuid.uuid4()))
    repo      = job["repo"]
    branch    = job.get("branch", "main")
    script    = job.get("script", "run_tests.sh")

    workspace = f"/tmp/{job_id}"
    os.makedirs(workspace, exist_ok=True)

    try:
        # Clone & checkout
        subprocess.check_call(["git", "clone", repo, workspace])
        subprocess.check_call(["git", "-C", workspace, "checkout", branch])

        # Run the test script
        result = subprocess.run(
            ["bash", f"{workspace}/{script}"],
            capture_output=True,
            text=True,
            check=False
        )

        # Prepare log
        log_data = f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        key = f"logs/{job_id}-{int(time.time())}.log"

        # Upload to S3
        s3.put_object(Bucket=ARTIFACTS_BUCKET, Key=key, Body=log_data.encode())

        success = (result.returncode == 0)
        return success, key

    finally:
        # Clean up workspace
        shutil.rmtree(workspace, ignore_errors=True)

def main():
    print(f"Starting job processor, polling {QUEUE_URL}")
    while True:
        resp = sqs.receive_message(
            QueueUrl            = QUEUE_URL,
            MaxNumberOfMessages = 1,
            WaitTimeSeconds     = 20
        )
        messages = resp.get("Messages", [])
        if not messages:
            time.sleep(POLL_INTERVAL)
            continue

        for msg in messages:
            receipt = msg["ReceiptHandle"]
            success, s3_key = process_message(msg["Body"])
            if success:
                sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=receipt)
                print(f"Job succeeded, logs at s3://{ARTIFACTS_BUCKET}/{s3_key}")
            else:
                print(f"Job failed, retaining message for retry: {msg['MessageId']}")

if __name__ == "__main__":
    main()
