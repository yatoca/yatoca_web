#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${STACK_NAME:-yatoca-web}"
AWS_REGION="${AWS_REGION:-us-east-1}"

WEB_BUCKET_NAME="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='WebBucketName'].OutputValue | [0]" \
  --output text)"

DISTRIBUTION_ID="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue | [0]" \
  --output text)"

npm ci
npm run build

aws s3 sync out/ "s3://${WEB_BUCKET_NAME}/" --delete
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths '/*' >/dev/null

echo "Static site deployed to s3://${WEB_BUCKET_NAME}/"
echo "CloudFront invalidation requested for ${DISTRIBUTION_ID}"
