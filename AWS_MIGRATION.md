# Yatoca AWS migration — COMPLETE

Production cutover completed on **2026-09-12**.

The live architecture is now:

```text
Route 53 -> CloudFront
              |-- private S3 static site
              |-- /media/* -> private S3 assets
              `-- /api/* -> API Gateway -> Lambda -> DynamoDB
```

Production domains:

- `https://yatoca.pe`
- `https://www.yatoca.pe`

The website no longer uses PostgreSQL in the production request path.

## Current infrastructure source

The running application stack remains managed by CloudFormation/SAM in:

```text
infrastructure/template.yaml
```

Portable new-account reconstruction is documented and implemented in:

```text
docs/AWS_PRODUCTION_ARCHITECTURE.md
docs/NEW_AWS_ACCOUNT_RECOVERY.md
docs/DIGITALOCEAN_DECOMMISSION.md
infrastructure/terraform/
```

## Normal web deployment

```bash
./scripts/deploy-web.sh
```

## Infrastructure deployment safety

Production CloudFront now requires the issued ACM certificate. `scripts/deploy-infra.sh` automatically discovers the issued `yatoca.pe` certificate when `CERTIFICATE_ARN` is not explicitly provided and refuses deployment if it cannot find one.

This prevents an accidental redeploy from removing the production aliases/certificate.

## DNS

Route 53 is authoritative. The pre-cutover DigitalOcean DNS staging script has been disabled intentionally.

Never rerun the old pre-cutover DNS change set. It pointed the website back to DigitalOcean.

## Historical data

Historical PostgreSQL data is archived separately in database/CSV backups. It is **not** imported into DynamoDB. DynamoDB stores new website feedback after the AWS cutover.

## Security

A DigitalOcean Spaces credential used during migration was exposed. Revoke/delete it. Do not reuse it or include it in any archive.
