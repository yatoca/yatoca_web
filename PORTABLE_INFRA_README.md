# Yatoca portable infrastructure package

This package was generated from the post-migration Yatoca infrastructure source after the production cutover on 2026-09-12.

## Start here

- `AWS_MIGRATION.md` — migration status and safe current deployment behavior
- `docs/AWS_PRODUCTION_ARCHITECTURE.md` — canonical live architecture
- `docs/NEW_AWS_ACCOUNT_RECOVERY.md` — staged account-migration/disaster-recovery procedure
- `docs/DIGITALOCEAN_DECOMMISSION.md` — safe legacy shutdown order
- `docs/DATA_ARCHIVE_AND_RECOVERY.md` — PostgreSQL backup posture
- `docs/INFRASTRUCTURE_MANIFEST.md` — ownership/resource map
- `infrastructure/terraform/README.md` — Terraform usage

## Important

The current production resources are still owned by CloudFormation/manual AWS resources. The Terraform configuration is for reconstruction in a **new AWS account**. Do not apply it in the current production account without a deliberate Terraform import/ownership migration.

A future **cross-account** move also requires an explicit CloudFront alternate-domain-name transfer. DNS/Route 53 alone cannot move `yatoca.pe` from one CloudFront distribution to another. See `docs/NEW_AWS_ACCOUNT_RECOVERY.md`.

## Safety changes included

This package also fixes two dangerous post-cutover leftovers from the pre-cutover source:

1. `scripts/deploy-infra.sh` no longer silently deploys with an empty ACM certificate ARN. It discovers the issued production certificate or fails closed.
2. `scripts/stage-dns.sh` is disabled because the old staging DNS change set would point the website back to DigitalOcean.

The old DNS snapshot is retained only as:

```text
infrastructure/dns-pre-cutover-digitalocean-backup.json
```

for historical/rollback reference.
