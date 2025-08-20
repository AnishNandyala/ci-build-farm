#!/usr/bin/env python3
import os
import time
import json
import uuid
import shutil
import subprocess
import boto3

# ─── Configuration from environment ───────────────────────────────────────────
QUEUE_URL        = os.environ["QUEUE_URL"]
ARTIFACTS_BUCKET = os.environ["ARTIFACTS_BUCKET"]
AWS_REGION       = os.environ.get("AWS_REGION", "us-east-1")
POLL_INTERVAL    = int(os.environ.get("POLL_INTERVAL", "5"))

sqs = boto3.client("sqs", region_name=AWS_REGION)
s3  = boto3.client("s3", region_name=AWS_REGION)

def process_message(msg):
    body      = json.loads(msg["Body"])
    job_id    = body.get("id", str(uuid.uuid4()))
    repo      = body["repo"]
    branch    = body.get("branch", "main")
    script    = body.get("script", "run_tests.sh")
    workspace = f"/tmp/{job_id}"

    os.makedirs(workspace, exist_ok=True)
    try:
        # 1) Clone & checkout
        subprocess.check_call(["git", "clone", repo, workspace])
        subprocess.check_call(["git", "-C", workspace, "checkout", branch])

        # 2) Run the test script
        result = subprocess.run(
            ["bash", f"{workspace}/{script}"],
            capture_output=True,
            text=True
        )

        # 3) Prepare & upload logs
        log = f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        key = f"logs/{job_id}-{int(time.time())}.log"
        s3.put_object(Bucket=ARTIFACTS_BUCKET, Key=key, Body=log.encode())

        # 4) Delete message on success
        if result.returncode == 0:
            sqs.delete_message(
                QueueUrl=QUEUE_URL,
                ReceiptHandle=msg["ReceiptHandle"]
            )
            print(f"[+] Job {job_id} succeeded, logs at s3://{ARTIFACTS_BUCKET}/{key}")
        else:
            print(f"[-] Job {job_id} failed (exit {result.returncode}); will retry later")

    finally:
        shutil.rmtree(workspace, ignore_errors=True)


def main():
    print(f"→ Starting agent. Polling {QUEUE_URL} every {POLL_INTERVAL}s")
    while True:
        resp = sqs.receive_message(
            QueueUrl            = QUEUE_URL,
            MaxNumberOfMessages = 1,
            WaitTimeSeconds     = 20
        )
        msgs = resp.get("Messages", [])
        if not msgs:
            time.sleep(POLL_INTERVAL)
            continue

        for msg in msgs:
            process_message(msg)

if __name__ == "__main__":
    main()
