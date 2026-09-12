#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${STACK_NAME:-yatoca-web}"
AWS_REGION="${AWS_REGION:-us-east-1}"
FEEDBACK_TABLE_NAME="${FEEDBACK_TABLE_NAME:-yatoca-feedback}"
DOMAIN_NAME="${DOMAIN_NAME:-yatoca.pe}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
WEB_BUCKET_NAME="${WEB_BUCKET_NAME:-yatoca-web-${ACCOUNT_ID}}"
ASSETS_BUCKET_NAME="${ASSETS_BUCKET_NAME:-yatoca-assets-${ACCOUNT_ID}}"
DEPLOY_BUCKET_NAME="${DEPLOY_BUCKET_NAME:-yatoca-deploy-${ACCOUNT_ID}}"
CERTIFICATE_ARN="${CERTIFICATE_ARN:-}"
PACKAGED_TEMPLATE="$(mktemp -t yatoca-packaged.XXXXXX.yaml)"
trap 'rm -f "$PACKAGED_TEMPLATE"' EXIT

# Production aliases are live. Never silently redeploy CloudFront with the
# default certificate. If the caller did not provide an ARN, discover the
# issued apex certificate in the required CloudFront ACM region.
if [[ -z "$CERTIFICATE_ARN" ]]; then
  CERTIFICATE_ARN="$(aws acm list-certificates \
    --region us-east-1 \
    --certificate-statuses ISSUED \
    --query "CertificateSummaryList[?DomainName=='${DOMAIN_NAME}'].CertificateArn | [0]" \
    --output text)"
fi

if [[ -z "$CERTIFICATE_ARN" || "$CERTIFICATE_ARN" == "None" ]]; then
  echo "Refusing infrastructure deployment: no ISSUED ACM certificate found for ${DOMAIN_NAME} in us-east-1." >&2
  echo "Set CERTIFICATE_ARN explicitly if needed." >&2
  exit 1
fi

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
    AssetsBucketName="$ASSETS_BUCKET_NAME" \
    FeedbackTableName="$FEEDBACK_TABLE_NAME" \
    CertificateArn="$CERTIFICATE_ARN"

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs' \
  --output table
