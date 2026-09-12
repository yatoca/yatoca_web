#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${TF_DIR:-${REPO_ROOT}/infrastructure/terraform}"

WEB_BUCKET_NAME="$(terraform -chdir="$TF_DIR" output -raw web_bucket_name)"
DISTRIBUTION_ID="$(terraform -chdir="$TF_DIR" output -raw cloudfront_distribution_id)"

cd "$REPO_ROOT"
npm ci
npm run build
aws s3 sync out/ "s3://${WEB_BUCKET_NAME}/" --delete
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths '/*' >/dev/null

echo "Static site deployed to s3://${WEB_BUCKET_NAME}/"
echo "CloudFront invalidation requested for ${DISTRIBUTION_ID}"
