#!/usr/bin/env bash
set -xeuo pipefail

# 1. Generate a unique job ID (timestamp)
JOB_ID=$(date +%s)
echo "→ JOB_ID = $JOB_ID"

# 2. Define your repo, branch and test script
REPO_URL="https://github.com/AnishNandyala/demoRepo.git"
BRANCH="main"
SCRIPT="run_tests.sh"
echo "→ Repo: $REPO_URL  Branch: $BRANCH  Script: $SCRIPT"

# 3. Retrieve your SQS queue URL from Terraform
#    Make sure you've already run `terraform apply` or this will hang prompting you.
QUEUE_URL=$(cd infra && terraform output -raw ci_build_queue_url)
echo "→ QUEUE_URL = $QUEUE_URL"

# 4. Build the JSON payload *without* jq
BODY=$(printf '{"id":"%s","repo":"%s","branch":"%s","script":"%s"}' \
    "$JOB_ID" "$REPO_URL" "$BRANCH" "$SCRIPT")
echo "→ Payload = $BODY"

# 5. Send the message
aws sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body "$BODY" \
  --output text

echo "✓ Job ${JOB_ID} queued on branch=${BRANCH}, script=${SCRIPT}"
