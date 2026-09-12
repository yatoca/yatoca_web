#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-aws-live-state-$(date +%Y%m%d-%H%M%S)}"
REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${STACK_NAME:-yatoca-web}"
DOMAIN="${DOMAIN:-yatoca.pe}"

mkdir -p "$OUT_DIR"

aws sts get-caller-identity > "$OUT_DIR/caller-identity.json"
aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" > "$OUT_DIR/cloudformation-stack.json"

DIST_ID="$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue | [0]" --output text)"
aws cloudfront get-distribution --id "$DIST_ID" > "$OUT_DIR/cloudfront-distribution.json"
aws cloudfront get-distribution-config --id "$DIST_ID" > "$OUT_DIR/cloudfront-config.json"

ZONE_ID="$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN" --query "HostedZones[?Name=='${DOMAIN}.'].Id | [0]" --output text | sed 's#^/hostedzone/##')"
aws route53 get-hosted-zone --id "$ZONE_ID" > "$OUT_DIR/route53-zone.json"
aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" > "$OUT_DIR/route53-records.json"

aws dynamodb describe-table --table-name yatoca-feedback --region "$REGION" > "$OUT_DIR/dynamodb-table.json"
aws acm list-certificates --region us-east-1 > "$OUT_DIR/acm-certificates.json"

printf 'Exported non-secret AWS state snapshots to %s\n' "$OUT_DIR"
