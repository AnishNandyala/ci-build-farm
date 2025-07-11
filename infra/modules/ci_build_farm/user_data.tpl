#!/usr/bin/env bash
set -euo pipefail

# ─── 1. System prep ─────────────────────────────────────────────────────────────
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# ─── 2. Install AWS CLI v2 (optional; only if your agent needs it) ─────────────
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi

# ─── 3. Export injected environment variables ──────────────────────────────────
export QUEUE_URL="${queue_url}"
export AGENT_IMAGE="${agent_image}"
export AWS_REGION="${aws_region}"
export ARTIFACTS_BUCKET="${project_name}-artifacts"

# ─── 4. Run your CI‐agent container ────────────────────────────────────────────
docker run --rm \
  -e QUEUE_URL="$QUEUE_URL" \
  -e AWS_REGION="$AWS_REGION" \
  -e ARTIFACTS_BUCKET="$ARTIFACTS_BUCKET" \
  "$AGENT_IMAGE"