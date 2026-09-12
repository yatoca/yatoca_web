# DigitalOcean decommission checklist

The live Yatoca website is now on AWS. DigitalOcean should be removed deliberately, not all at once.

## Immediate security cleanup

- [ ] Revoke/delete the DigitalOcean Spaces access credential exposed during migration.
- [ ] Do not publish or store that credential in documentation, shell history exports, tickets, or Git.

Revoking the credential does not require deleting the Space.

## Keep during rollback window

- [ ] old DigitalOcean application
- [ ] old PostgreSQL database
- [ ] old Space/media objects
- [ ] old DigitalOcean DNS zone if convenient (it is no longer authoritative)

The DNS zone itself cannot override Route 53 once the registrar delegation points to AWS.

## Before deleting PostgreSQL

- [ ] retain the custom-format `pg_dump` backup
- [ ] retain the business CSV exports
- [ ] retain protected raw CSV exports if needed
- [ ] perform one disposable PostgreSQL restore test before permanent DB deletion
- [ ] record a SHA-256 checksum for the final DB dump

## Before deleting Spaces

- [ ] verify `/media/*` URLs through production CloudFront
- [ ] retain a separate local/off-account media backup
- [ ] compare expected media object count/size against the AWS assets bucket

## Before deleting the old app

- [ ] `https://yatoca.pe/` and `https://www.yatoca.pe/` are stable on AWS
- [ ] all major routes return expected status codes
- [ ] feedback submissions reach DynamoDB
- [ ] no production source code references the old `ondigitalocean.app` hostname or Spaces CDN hostname

## Email safety

DigitalOcean email DNS records were copied to Route 53. Before deleting the old DNS zone, confirm public DNS still returns:

- Google MX records
- apex TXT records including SPF and Google verification
- DMARC
- Mailchimp DKIM (`k2`, `k3`)
- Titan DKIM (`s1`, `s2`)

## Suggested order

1. Revoke the exposed Spaces credential now.
2. Keep old runtime resources for the rollback window.
3. Test DB restore.
4. Confirm off-account backups.
5. Delete old app/runtime.
6. Delete old managed PostgreSQL after restore verification.
7. Delete old Space only after media backup verification.
8. Delete the obsolete DigitalOcean DNS zone last.
