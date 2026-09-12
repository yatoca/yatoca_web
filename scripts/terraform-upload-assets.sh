#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/media-backup" >&2
  exit 2
fi

SOURCE_DIR="$1"
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Directory not found: $SOURCE_DIR" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${TF_DIR:-${REPO_ROOT}/infrastructure/terraform}"
ASSETS_BUCKET_NAME="$(terraform -chdir="$TF_DIR" output -raw assets_bucket_name)"

aws s3 sync "$SOURCE_DIR/" "s3://${ASSETS_BUCKET_NAME}/media/"

echo "Uploaded media to s3://${ASSETS_BUCKET_NAME}/media/"
aws s3 ls "s3://${ASSETS_BUCKET_NAME}/media/" --recursive --summarize | tail -2
