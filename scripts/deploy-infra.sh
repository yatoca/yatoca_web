#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${STACK_NAME:-yatoca-web}"
AWS_REGION="${AWS_REGION:-us-east-1}"
FEEDBACK_TABLE_NAME="${FEEDBACK_TABLE_NAME:-yatoca-feedback}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
WEB_BUCKET_NAME="${WEB_BUCKET_NAME:-yatoca-web-${ACCOUNT_ID}}"
DEPLOY_BUCKET_NAME="${DEPLOY_BUCKET_NAME:-yatoca-deploy-${ACCOUNT_ID}}"
CERTIFICATE_ARN="${CERTIFICATE_ARN:-}"
PACKAGED_TEMPLATE="$(mktemp -t yatoca-packaged.XXXXXX.yaml)"
trap 'rm -f "$PACKAGED_TEMPLATE"' EXIT

if ! aws s3api head-bucket --bucket "$DEPLOY_BUCKET_NAME" 2>/dev/null; then
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$DEPLOY_BUCKET_NAME" --region "$AWS_REGION" >/dev/null
  else
    aws s3api create-bucket \
      --bucket "$DEPLOY_BUCKET_NAME" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null
  fi

  aws s3api put-public-access-block \
    --bucket "$DEPLOY_BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
fi

aws cloudformation package \
  --template-file infrastructure/template.yaml \
  --s3-bucket "$DEPLOY_BUCKET_NAME" \
  --output-template-file "$PACKAGED_TEMPLATE" \
  --region "$AWS_REGION"

aws cloudformation deploy \
  --template-file "$PACKAGED_TEMPLATE" \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
  --no-fail-on-empty-changeset \
  --parameter-overrides \
    WebBucketName="$WEB_BUCKET_NAME" \
    FeedbackTableName="$FEEDBACK_TABLE_NAME" \
    CertificateArn="$CERTIFICATE_ARN"

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs' \
  --output table
