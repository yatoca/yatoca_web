# Yatoca AWS production architecture

Status: **Production cutover completed 2026-09-12**.

This document describes the live Yatoca infrastructure after migration from DigitalOcean to AWS. It is the canonical operational reference for the current AWS account. The Terraform directory is a separate disaster-recovery/account-migration definition and must not be applied to the current account unless the existing resources are imported first.

## 1. Live request path

```text
yatoca.pe / www.yatoca.pe
        |
        v
    Route 53
        |
        v
    CloudFront
      |   |   \
      |   |    +--> /api/* --> API Gateway HTTP API --> Lambda --> DynamoDB
      |   +-------> /media/* --> private S3 assets bucket through OAC
      +-----------> default --> private S3 web bucket through OAC
```

The production website no longer depends on the old PostgreSQL database.

## 2. Current AWS resources

Application region: `us-east-1`.

| Component | Current resource |
|---|---|
| CloudFormation stack | `yatoca-web` |
| Static web bucket | `yatoca-web-859485560023` |
| Media/assets bucket | `yatoca-assets-859485560023` |
| CloudFront distribution | `E3GRBAM49C7O12` |
| CloudFront hostname | `dp6hdjg6u5zsm.cloudfront.net` |
| API Gateway endpoint | `https://jib7oah0c0.execute-api.us-east-1.amazonaws.com` |
| DynamoDB table | `yatoca-feedback` |
| Route 53 hosted zone | `Z0628504M3ENTXTEYAYA` |
| ACM certificate | `arn:aws:acm:us-east-1:859485560023:certificate/a858ab3d-0efe-489a-89a5-64091ed604e6` |
| Source repository | CodeCommit `yatoca-web`, region `us-east-2` |

The CloudFront distribution uses:

- OAC to read both private S3 buckets.
- `PriceClass_100`.
- HTTP/2 + HTTP/3.
- AWS managed `CachingOptimized` policy for static/media content.
- AWS managed `CachingDisabled` plus `AllViewerExceptHostHeader` for `/api/*`.
- A CloudFront Function that rewrites extensionless static-export paths to `index.html` while skipping `/api/*`.
- ACM TLS certificate for `yatoca.pe` and `www.yatoca.pe`.

## 3. DNS

Registrar nameservers currently delegate to Route 53:

```text
ns-773.awsdns-32.net
ns-284.awsdns-35.com
ns-1852.awsdns-39.co.uk
ns-1348.awsdns-40.org
```

Website records:

- Apex `A` alias -> CloudFront.
- Apex `AAAA` alias -> CloudFront.
- `www` `A` alias -> CloudFront.
- `www` `AAAA` alias -> CloudFront.

Mail/service DNS was intentionally preserved unchanged during the migration:

```text
MX  1 aspmx.l.google.com.
MX  3 alt2.aspmx.l.google.com.
MX  5 alt1.aspmx.l.google.com.
MX  8 alt3.aspmx.l.google.com.
MX  8 alt4.aspmx.l.google.com.

TXT "google-site-verification=iSQT41lsnYz-EALupDo9IJaspvaTSF7kd7wQEQm2gtk"
TXT "T4409132"
TXT "v=spf1 include:secureserver.net -all"

_dmarc TXT "v=DMARC1; p=quarantine; rua=mailto:postmaster@yatoca.pe; pct=100"
k2._domainkey CNAME dkim2.mcsv.net.
k3._domainkey CNAME dkim3.mcsv.net.
s1._domainkey CNAME s1.domainkey.titan.email.
s2._domainkey CNAME s2.domainkey.titan.email.
```

Do not remove the ACM validation CNAME records. ACM uses them for managed renewal.

## 4. Static site

The app is a Next.js static export (`output: "export"`, `trailingSlash: true`). `scripts/deploy-web.sh` performs:

1. `npm ci`
2. `npm run build`
3. `aws s3 sync out/ s3://<web-bucket>/ --delete`
4. CloudFront invalidation of `/*`

The current production stack obtains the web bucket and distribution ID from CloudFormation outputs.

## 5. Media

Legacy DigitalOcean Spaces media was copied to:

```text
s3://yatoca-assets-859485560023/media/
```

Application references use `/media/...`, which CloudFront routes to the private assets bucket.

The old Space should only be removed after the rollback window is closed and a separate backup is retained.

## 6. Feedback API

Routes:

```text
GET  /api/opiniones-hero
POST /api/opiniones-hero
POST /api/opiniones
```

Lambda runtime: Node.js 22, arm64, 128 MB, 10 second timeout.

### Hero submissions

Request:

```json
{"message":"text up to 30 characters"}
```

DynamoDB item:

```text
pk         = HERO
sk         = <ISO timestamp>#<UUID>
comentario = submitted message
fecha      = ISO timestamp
createdAt  = ISO timestamp
```

`GET /api/opiniones-hero` queries `pk = HERO`, newest first, up to 100 results.

### Questionnaire submissions

At least one of `q1`, `q2`, `q3` must be present. `age_group` is required and must be one of:

```text
16-29
30-45
46+
```

DynamoDB item:

```text
pk        = QUESTION
sk        = <ISO timestamp>#<UUID>
age_group = selected age group
q1/q2/q3  = only the answers that were provided
fecha     = ISO timestamp
createdAt = ISO timestamp
```

Historical PostgreSQL opinion data was intentionally **not** migrated to DynamoDB. The legacy data is retained in CSV/database backups; DynamoDB is the source for new submissions after cutover.

## 7. Production validation

Run:

```bash
./scripts/verify-production.sh
```

Expected essentials:

- `https://yatoca.pe/` -> HTTP 200 from CloudFront/S3.
- `https://www.yatoca.pe/` -> HTTP 200.
- `/api/opiniones-hero` -> JSON success response from the AWS API.
- Public NS -> the four AWS nameservers.
- MX/TXT/DMARC/DKIM records remain present.

## 8. Infrastructure ownership

### Current production

The currently deployed application infrastructure is still owned by the existing CloudFormation/SAM stack in `infrastructure/template.yaml`.

### Disaster recovery / new AWS account

`infrastructure/terraform/` is a **portable reconstruction definition**. It covers the complete target architecture, including resources that were originally created manually (DynamoDB, Route 53 and ACM).

Do not run Terraform against this current account without importing the already-existing resources into Terraform state. Otherwise Terraform will attempt to create duplicates and may conflict with CloudFormation.

## 9. Security notes

- A DigitalOcean Spaces credential was exposed during migration. Revoke/delete that credential immediately. Do not reuse it.
- Never commit `.env`, AWS credentials, DigitalOcean credentials, Terraform state, or generated Lambda zip files.
- The ACM DNS validation records are not secrets and should remain in DNS.
- The legacy PostgreSQL dump and participant exports contain personal information and must be stored as protected backups.

## 10. Known follow-up work

- Upgrade Next.js to the next fully patched supported major/version in a separate change. The current dependency tree still reports audit findings; do not use an unreviewed forced major upgrade in production.
- Remove unused packages (`pg`, `dotenv`, and possibly other unused front-end dependencies) only after confirming they are no longer referenced.
- Decide whether to add automated build/deploy later. The current deployment scripts are intentionally simple and inexpensive.
