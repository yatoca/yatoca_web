#!/usr/bin/env bash
set -euo pipefail

if [[ "${ALLOW_LEGACY_DO_MIGRATION:-}" != "1" ]]; then
  cat >&2 <<'MSG'
This one-time DigitalOcean Spaces migration has already been completed.
It is disabled by default because the old Spaces credential must be revoked.

For disaster recovery, use scripts/terraform-upload-assets.sh with a trusted
local/off-account media backup instead.

If you intentionally need the historical migration workflow with a newly
created safe credential, rerun with ALLOW_LEGACY_DO_MIGRATION=1.
MSG
  exit 1
fi

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

mkdir -p "$BACKUP_DIR"

aws s3 sync \
  "s3://${DO_SPACE}" \
  "$BACKUP_DIR" \
  --endpoint-url "$DO_ENDPOINT" \
  --profile "$DO_PROFILE"

aws s3 sync \
  "$BACKUP_DIR" \
  "s3://${ASSETS_BUCKET_NAME}/media/"

echo "Legacy media copy completed."
