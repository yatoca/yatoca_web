#!/usr/bin/env bash
set -euo pipefail

# Isolated Terraform disaster-recovery rehearsal for Yatoca.
# Creates a temporary, uniquely named copy of the infrastructure in the
# CURRENT AWS account, validates the key paths, then destroys it.
# It never attaches yatoca.pe/www.yatoca.pe and never changes registrar DNS.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
STAMP="$(date -u +%Y%m%d%H%M%S)"
SHORT="${STAMP:2}"
PROJECT="yatoca-drtest-${SHORT}"
DOMAIN="drtest-${SHORT}.yatoca.pe"
TABLE="${PROJECT}-feedback"
WORK="${TMPDIR:-/tmp}/${PROJECT}"
LOG_DIR="${REPO_ROOT}/migration-backup"
LOG="${LOG_DIR}/terraform-dr-rehearsal-${STAMP}.log"
APPLY_ATTEMPTED=0
CLEANUP_DONE=0

mkdir -p "$WORK/repo/infrastructure" "$LOG_DIR"
exec > >(tee -a "$LOG") 2>&1

echo "Yatoca Terraform DR rehearsal"
echo "UTC stamp: $STAMP"
echo "Project: $PROJECT"
echo "Test domain (not delegated): $DOMAIN"
echo "Work dir: $WORK"
echo "Log: $LOG"
echo

for cmd in aws terraform jq curl; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: required command not found: $cmd" >&2
    exit 1
  }
done

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
echo "AWS account: $ACCOUNT_ID"
echo "AWS region: $AWS_REGION"
echo

# Copy only what Terraform needs, excluding any production/local state.
cp -R "${REPO_ROOT}/infrastructure/terraform" "$WORK/repo/infrastructure/terraform"
cp -R "${REPO_ROOT}/lambda" "$WORK/repo/lambda"
rm -rf "$WORK/repo/infrastructure/terraform/.terraform" \
       "$WORK/repo/infrastructure/terraform/terraform.tfstate" \
       "$WORK/repo/infrastructure/terraform/terraform.tfstate.backup" \
       "$WORK/repo/infrastructure/terraform/.terraform.tfstate.lock.info"

TF_DIR="$WORK/repo/infrastructure/terraform"
TFVARS="$TF_DIR/dr-rehearsal.tfvars"

cat > "$TFVARS" <<EOF
aws_region               = "$AWS_REGION"
codecommit_region        = "us-east-2"
project_name             = "$PROJECT"
domain_name              = "$DOMAIN"
feedback_table_name      = "$TABLE"
create_hosted_zone       = true
attach_custom_certificate = false
enable_custom_domain     = false
cloudfront_price_class   = "PriceClass_100"
enable_codecommit        = false
budget_email             = null
EOF

cleanup_versioned_bucket() {
  local bucket="$1"
  local delete_json="$WORK/delete-${bucket}.json"

  aws s3api list-object-versions --bucket "$bucket" --output json \
    | jq '{Objects: ([.Versions[]?, .DeleteMarkers[]?] | map({Key:.Key,VersionId:.VersionId})), Quiet:true}' \
    > "$delete_json"

  if [[ "$(jq '.Objects | length' "$delete_json")" -gt 0 ]]; then
    aws s3api delete-objects --bucket "$bucket" --delete "file://${delete_json}" >/dev/null
  fi
}

cleanup() {
  local rc=$?
  if [[ "$CLEANUP_DONE" -eq 1 ]]; then
    return "$rc"
  fi
  CLEANUP_DONE=1

  if [[ "$APPLY_ATTEMPTED" -eq 1 && -f "$TF_DIR/terraform.tfstate" ]]; then
    echo
    echo "=== Cleanup temporary DR resources ==="

    local web_bucket assets_bucket backup_bucket table_name
    web_bucket="$(terraform -chdir="$TF_DIR" output -raw web_bucket_name 2>/dev/null || true)"
    assets_bucket="$(terraform -chdir="$TF_DIR" output -raw assets_bucket_name 2>/dev/null || true)"
    backup_bucket="$(terraform -chdir="$TF_DIR" output -raw backup_bucket_name 2>/dev/null || true)"
    table_name="$(terraform -chdir="$TF_DIR" output -raw feedback_table_name 2>/dev/null || true)"

    if [[ -n "$table_name" && "$table_name" == yatoca-drtest-* ]]; then
      aws dynamodb update-table \
        --table-name "$table_name" \
        --region "$AWS_REGION" \
        --no-deletion-protection-enabled >/dev/null 2>&1 || true
      aws dynamodb wait table-exists \
        --table-name "$table_name" \
        --region "$AWS_REGION" >/dev/null 2>&1 || true
    fi

    if [[ -n "$web_bucket" && "$web_bucket" == yatoca-drtest-* ]]; then
      aws s3 rm "s3://${web_bucket}/" --recursive >/dev/null 2>&1 || true
    fi
    if [[ -n "$assets_bucket" && "$assets_bucket" == yatoca-drtest-* ]]; then
      cleanup_versioned_bucket "$assets_bucket" || true
    fi
    if [[ -n "$backup_bucket" && "$backup_bucket" == yatoca-drtest-* ]]; then
      cleanup_versioned_bucket "$backup_bucket" || true
    fi

    terraform -chdir="$TF_DIR" destroy \
      -auto-approve \
      -var-file="$TFVARS" || {
        echo "WARNING: automatic destroy did not finish. Keep $WORK and use its Terraform state to finish cleanup." >&2
        return "$rc"
      }

    echo "Temporary DR infrastructure destroyed."
  fi

  if [[ "$rc" -eq 0 ]]; then
    rm -rf "$WORK"
  else
    echo "Rehearsal failed with exit code $rc; work directory preserved: $WORK" >&2
  fi

  return "$rc"
}
trap cleanup EXIT

echo "=== Terraform init / validate / plan ==="
terraform -chdir="$TF_DIR" init -backend=false
terraform -chdir="$TF_DIR" validate
terraform -chdir="$TF_DIR" plan \
  -var-file="$TFVARS" \
  -out="$WORK/dr-rehearsal.tfplan"

echo
read -r -p "Apply isolated DR infrastructure in AWS account ${ACCOUNT_ID}? [y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  echo "Cancelled before apply."
  exit 0
fi

APPLY_ATTEMPTED=1
terraform -chdir="$TF_DIR" apply -auto-approve "$WORK/dr-rehearsal.tfplan"

echo

echo "=== Terraform outputs ==="
terraform -chdir="$TF_DIR" output

WEB_BUCKET="$(terraform -chdir="$TF_DIR" output -raw web_bucket_name)"
ASSETS_BUCKET="$(terraform -chdir="$TF_DIR" output -raw assets_bucket_name)"
BACKUP_BUCKET="$(terraform -chdir="$TF_DIR" output -raw backup_bucket_name)"
API_ENDPOINT="$(terraform -chdir="$TF_DIR" output -raw api_endpoint)"
CF_DOMAIN="$(terraform -chdir="$TF_DIR" output -raw cloudfront_domain_name)"
TABLE_NAME="$(terraform -chdir="$TF_DIR" output -raw feedback_table_name)"
API_ID="${API_ENDPOINT#https://}"
API_ID="${API_ID%%.*}"

for value in "$WEB_BUCKET" "$ASSETS_BUCKET" "$BACKUP_BUCKET" "$TABLE_NAME"; do
  [[ "$value" == yatoca-drtest-* ]] || {
    echo "SAFETY ERROR: unexpected temporary resource name: $value" >&2
    exit 2
  }
done

# Seed tiny test objects; no production data is copied.
printf '%s\n' '<!doctype html><title>Yatoca DR rehearsal</title><h1>Yatoca DR rehearsal OK</h1>' > "$WORK/index.html"
mkdir -p "$WORK/home"
printf '%s\n' '<!doctype html><title>Yatoca DR home</title><h1>rewrite OK</h1>' > "$WORK/home/index.html"
printf '%s\n' 'media route OK' > "$WORK/media-test.txt"

aws s3 cp "$WORK/index.html" "s3://${WEB_BUCKET}/index.html" --content-type text/html >/dev/null
aws s3 cp "$WORK/home/index.html" "s3://${WEB_BUCKET}/home/index.html" --content-type text/html >/dev/null
aws s3 cp "$WORK/media-test.txt" "s3://${ASSETS_BUCKET}/media/dr-rehearsal.txt" --content-type text/plain >/dev/null

# CloudFront is created with wait_for_deployment=true, but give edge propagation a few retries.
echo
echo "=== CloudFront / OAC smoke ==="
for path in / /home/ /media/dr-rehearsal.txt; do
  ok=0
  for attempt in {1..12}; do
    code="$(curl -sS -o "$WORK/curl-body" -w '%{http_code}' "https://${CF_DOMAIN}${path}" || true)"
    if [[ "$code" == "200" ]]; then
      echo "$path -> 200"
      ok=1
      break
    fi
    echo "$path -> $code (attempt $attempt/12)"
    sleep 5
  done
  [[ "$ok" -eq 1 ]] || {
    echo "ERROR: CloudFront smoke failed for $path" >&2
    exit 3
  }
done

echo
echo "=== API + DynamoDB smoke ==="
curl -fsS "https://${CF_DOMAIN}/api/opiniones-hero" | tee "$WORK/api-before.json"
echo
curl -fsS -X POST "https://${CF_DOMAIN}/api/opiniones-hero" \
  -H 'content-type: application/json' \
  --data '{"message":"DR rehearsal"}' | tee "$WORK/api-post.json"
echo
curl -fsS "https://${CF_DOMAIN}/api/opiniones-hero" | tee "$WORK/api-after.json"
echo
jq -e '.success == true' "$WORK/api-before.json" >/dev/null
jq -e '.success == true' "$WORK/api-post.json" >/dev/null
jq -e '.success == true and any(.data[]?; .comentario == "DR rehearsal")' "$WORK/api-after.json" >/dev/null

echo
echo "=== Hardening checks ==="
aws apigatewayv2 get-stage \
  --api-id "$API_ID" \
  --stage-name '$default' \
  --region "$AWS_REGION" \
  --query 'RouteSettings' \
  --output json | tee "$WORK/route-settings.json"

jq -e '.["POST /api/opiniones"].ThrottlingBurstLimit == 20 and .["POST /api/opiniones"].ThrottlingRateLimit == 5' "$WORK/route-settings.json" >/dev/null
jq -e '.["POST /api/opiniones-hero"].ThrottlingBurstLimit == 20 and .["POST /api/opiniones-hero"].ThrottlingRateLimit == 5' "$WORK/route-settings.json" >/dev/null

[[ "$(aws s3api get-bucket-versioning --bucket "$ASSETS_BUCKET" --query Status --output text)" == "Enabled" ]]
[[ "$(aws s3api get-bucket-versioning --bucket "$BACKUP_BUCKET" --query Status --output text)" == "Enabled" ]]
[[ "$(aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" --query 'Table.DeletionProtectionEnabled' --output text)" == "True" ]]
[[ "$(aws dynamodb describe-continuous-backups --table-name "$TABLE_NAME" --region "$AWS_REGION" --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.RecoveryPeriodInDays' --output text)" == "35" ]]
[[ "$(aws logs describe-log-groups --region "$AWS_REGION" --log-group-name-prefix "/aws/lambda/${PROJECT}-api" --query 'logGroups[0].retentionInDays' --output text)" == "30" ]]

echo
echo "PASS: Terraform created the isolated Yatoca infrastructure and all smoke/hardening checks passed."
echo "The EXIT cleanup will now destroy all temporary resources."
