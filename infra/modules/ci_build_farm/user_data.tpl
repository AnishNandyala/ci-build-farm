#!/usr/bin/env bash
set -xe

# 1) Install & start Docker
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker

# 2) Create env‑dir before writing the file
mkdir -p /etc/ci-agent

# 3) Dump the needed variables into /etc/ci-agent/env
cat > /etc/ci-agent/env <<EOF
QUEUE_URL=${queue_url}
ARTIFACTS_BUCKET=${artifacts_bucket_id}
AWS_REGION=${aws_region}
EOF

# 4) Launch the agent container with host networking
docker run -d \
  --net host \
  --env-file /etc/ci-agent/env \
  --name ci-agent \
  ${agent_image}