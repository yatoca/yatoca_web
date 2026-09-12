# Recover/move Yatoca to a new AWS account

This runbook is for disaster recovery or a deliberate move to another AWS account. It is intentionally staged so website and email DNS are not changed until the target infrastructure is ready.

## Important CloudFront constraint

CloudFront alternate domain names are globally unique. The current production distribution already owns:

```text
yatoca.pe
www.yatoca.pe
```

A target distribution in another AWS account cannot simply add those names while the source distribution still owns them.

AWS provides a CloudFront domain-association move procedure. For a cross-account move, the source distribution must be disabled before `UpdateDomainAssociation` can transfer the domain. For an apex/root domain where that maintenance window is unacceptable, coordinate the move with AWS Support.

This is separate from Route 53 and separate from registrar nameserver delegation.

## Principles

1. Build the new infrastructure before changing registrar nameservers.
2. Preserve every mail/service DNS record exactly.
3. Validate the new ACM certificate before moving the CloudFront aliases.
4. Copy S3 content and deploy the static site before the alias move.
5. Move CloudFront alternate domain names deliberately; do not let Terraform collide with the old distribution.
6. Keep the old AWS account through a rollback window.

## What Terraform recreates

`infrastructure/terraform/` creates:

- private S3 web bucket
- private S3 assets bucket
- S3 public-access blocks and ownership controls
- CloudFront OAC and bucket policies
- CloudFront static route rewrite function
- API Gateway HTTP API
- Lambda + IAM permissions
- DynamoDB `yatoca-feedback`
- ACM certificate
- Route 53 hosted zone
- all current mail/service DNS records
- CloudFront distribution
- apex and `www` Route 53 aliases once domain mode is enabled
- optional empty CodeCommit repository (disabled by default)

It does **not** copy:

- web build objects
- media objects
- Git history/content
- DynamoDB records
- registrar delegation
- an already-owned CloudFront alternate domain name from another account

## Prerequisites

- Terraform >= 1.6
- AWS CLI authenticated to the **new** AWS account
- Node/npm
- source code checkout
- local media backup or access to the old assets bucket
- access to the domain registrar
- access to the currently authoritative DNS
- access to the old AWS account if performing a planned CloudFront alias move

## Phase 1 - create the target infrastructure without the production domain

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Keep:

```hcl
attach_custom_certificate = false
enable_custom_domain       = false
```

Record:

```bash
terraform output route53_name_servers
terraform output acm_validation_records
terraform output cloudfront_domain_name
terraform output cloudfront_distribution_id
terraform output web_bucket_name
terraform output assets_bucket_name
```

The target CloudFront distribution works only on its generated `*.cloudfront.net` hostname at this point.

## Phase 2 - validate ACM while old production stays live

The new Route 53 zone is not authoritative yet, so ACM cannot see validation records that exist only there.

Copy the CNAMEs shown by:

```bash
terraform output -json acm_validation_records
```

into the **currently authoritative DNS**. Keep the identical records in the new Route 53 zone because they are needed later for ACM managed renewal.

Wait in the new account until:

```bash
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn "$(terraform output -raw certificate_arn)" \
  --query 'Certificate.Status' \
  --output text
```

returns:

```text
ISSUED
```

## Phase 3 - attach the new certificate, but not the aliases

Change:

```hcl
attach_custom_certificate = true
enable_custom_domain       = false
```

Then:

```bash
terraform apply
```

This prepares the target distribution with the valid Yatoca certificate without trying to claim the domain names already owned by the source distribution.

## Phase 4 - copy media and deploy the web build

From the repository root:

```bash
./scripts/terraform-upload-assets.sh /path/to/ya-toca-web-imgs-backup
./scripts/terraform-deploy-web.sh
```

Test the target CloudFront hostname directly and confirm `/media/*` and `/api/*` work.

## Phase 5 - prepare cross-account CloudFront alias ownership proof

CloudFront requires ownership verification for cross-account domain moves. Terraform outputs the TXT records tied to the target distribution:

```bash
terraform output -json cloudfront_alias_transfer_verification_records
```

Publish those TXT records in the **currently authoritative DNS** before attempting the CloudFront alias move.

The records have the form:

```text
_.yatoca.pe      TXT <target-cloudfront-domain>
_www.yatoca.pe   TXT <target-cloudfront-domain>
```

## Phase 6 - move the CloudFront alternate domain names

### Preferred low-risk option for a planned apex move

Coordinate with AWS Support to move the apex/custom domain association if disabling the source distribution is not acceptable.

### Controlled maintenance option

If a brief maintenance window is acceptable and both accounts are accessible:

1. Disable the source CloudFront distribution in the old account and wait for the change to deploy.
2. In the target account, get the target distribution ETag.
3. Use the current AWS CLI `cloudfront update-domain-association` operation for each domain, targeting the new distribution.
4. Reconcile Terraform immediately afterward.

Example shape (verify against the installed AWS CLI version before executing):

```bash
TARGET_DIST_ID="$(terraform output -raw cloudfront_distribution_id)"
TARGET_ETAG="$(aws cloudfront get-distribution-config \
  --id "$TARGET_DIST_ID" \
  --query ETag \
  --output text)"

aws cloudfront update-domain-association \
  --domain yatoca.pe \
  --target-resource DistributionId="$TARGET_DIST_ID" \
  --if-match "$TARGET_ETAG"

# Refresh ETag before moving the next domain.
TARGET_ETAG="$(aws cloudfront get-distribution-config \
  --id "$TARGET_DIST_ID" \
  --query ETag \
  --output text)"

aws cloudfront update-domain-association \
  --domain www.yatoca.pe \
  --target-resource DistributionId="$TARGET_DIST_ID" \
  --if-match "$TARGET_ETAG"
```

After the move, set:

```hcl
attach_custom_certificate = true
enable_custom_domain       = true
```

and run:

```bash
terraform apply
```

Terraform can now safely declare the aliases because the old distribution no longer owns them.

## Phase 7 - point the currently authoritative DNS at the new CloudFront distribution

Before changing registrar nameservers, update the **currently authoritative Route 53 zone** to point apex and `www` A/AAAA aliases at the new target CloudFront distribution.

Verify:

```bash
curl -I https://yatoca.pe/
curl -I https://www.yatoca.pe/
curl -s https://yatoca.pe/api/opiniones-hero
```

This restores/keeps production traffic on the target distribution while the registrar still delegates to the old hosted zone.

## Phase 8 - move Route 53 authority to the new account

At the registrar, replace the old AWS nameservers with the new account's four nameservers from:

```bash
terraform output route53_name_servers
```

Do not modify Google Workspace itself. MX/TXT/DMARC/DKIM records are already present in the new Route 53 zone.

Monitor the `.pe` parent delegation and public resolvers.

## Phase 9 - validate production

Run:

```bash
./scripts/verify-production.sh
```

Also verify a real form submission reaches the new `yatoca-feedback` table.

## Phase 10 - rollback window

Keep the old account operational while DNS caches settle and users exercise production. If costs permit, use at least a 24-48 hour rollback window.

Do not delete the old account until:

- apex and `www` consistently serve the new CloudFront distribution
- media loads correctly
- APIs save/read new DynamoDB data
- Google mail delivery is verified
- ACM is `ISSUED`
- the new Route 53 zone is authoritative globally
- source code exists outside the old account
- media is backed up
- any data that must survive has been exported

## Complete-loss variation

If the old account is already unavailable, the CloudFront alias-move situation depends on whether the old distribution still exists/enabled. Use the CloudFront conflict/domain-association APIs and, when necessary, AWS Support. Registrar delegation can still be moved to the new Route 53 zone, but do not assume that DNS alone releases a CloudFront alternate domain name.
