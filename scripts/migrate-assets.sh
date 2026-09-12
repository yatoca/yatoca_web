#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${STACK_NAME:-yatoca-web}"
AWS_REGION="${AWS_REGION:-us-east-1}"
DO_PROFILE="${DO_PROFILE:-digitalocean-spaces}"
DO_SPACE="${DO_SPACE:-ya-toca-web-imgs}"
DO_ENDPOINT="${DO_ENDPOINT:-https://nyc3.digitaloceanspaces.com}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Desktop/projects/yatoca/ya-toca-web-imgs-backup}"

ASSETS_BUCKET_NAME="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='AssetsBucketName'].OutputValue | [0]" \
  --output text)"

if [[ -z "$ASSETS_BUCKET_NAME" || "$ASSETS_BUCKET_NAME" == "None" ]]; then
  echo "AssetsBucketName output not found. Deploy the updated infrastructure first." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "Downloading DigitalOcean Space to: $BACKUP_DIR"
aws s3 sync \
  "s3://${DO_SPACE}" \
  "$BACKUP_DIR" \
  --endpoint-url "$DO_ENDPOINT" \
  --profile "$DO_PROFILE"

echo "Uploading backup to AWS: s3://${ASSETS_BUCKET_NAME}/media/"
aws s3 sync \
  "$BACKUP_DIR" \
  "s3://${ASSETS_BUCKET_NAME}/media/"

LOCAL_COUNT="$(find "$BACKUP_DIR" -type f | wc -l | tr -d ' ')"
AWS_COUNT="$(aws s3api list-objects-v2 \
  --bucket "$ASSETS_BUCKET_NAME" \
  --prefix media/ \
  --query 'KeyCount' \
  --output text)"

echo "Local files: $LOCAL_COUNT"
echo "AWS objects under media/: $AWS_COUNT"
echo "Migration copy completed. Keep DigitalOcean intact until the CloudFront URLs are verified."
