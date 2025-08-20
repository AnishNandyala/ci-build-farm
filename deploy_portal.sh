#!/usr/bin/env bash
set -euo pipefail

BUCKET="my-portal-bucket"  # or read from terraform output
cd portal
npm ci
npm run build
aws s3 sync build/ "s3://$BUCKET/" --delete

# make sure index not cached:
aws s3 cp build/index.html "s3://$BUCKET/index.html" \
  --cache-control "no-cache, no-store, must-revalidate, max-age=0" \
  --content-type "text/html"
echo "Deployed: http://${BUCKET}.s3-website-<region>.amazonaws.com/"
