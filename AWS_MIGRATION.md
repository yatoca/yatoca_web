# Yatoca AWS migration

Target architecture:

- CodeCommit: source repository
- S3: private static Next.js export
- CloudFront: public CDN / HTTPS entry point
- API Gateway HTTP API: `/api/*`
- Lambda: feedback API
- DynamoDB: `yatoca-feedback`
- Route 53: authoritative DNS after a controlled cutover
- ACM (`us-east-1`): certificate for `yatoca.pe` and `www.yatoca.pe`

## Existing resources

The DynamoDB table `yatoca-feedback` and Route 53 hosted zone for `yatoca.pe` were created manually before this template. This stack intentionally references the DynamoDB table and does **not** mutate Route 53. DNS cutover is kept separate to minimize outage risk.

## DigitalOcean Spaces TODO

The application still references `https://ya-toca-web-imgs.nyc3.cdn.digitaloceanspaces.com/...`.

Do not delete that Space until those objects are copied to AWS and all references are updated. Migration is intentionally deferred because Spaces access keys are not currently available.

## Initial deployment

Prerequisites: AWS CLI and Node/npm. The infrastructure deployment uses AWS CLI + CloudFormation/SAM transform; a separate SAM CLI installation is not required.

```bash
export AWS_REGION=us-east-1
./scripts/deploy-infra.sh
./scripts/deploy-web.sh
```

The first deployment uses the default `*.cloudfront.net` hostname and does not require the production DNS or certificate.

## Production-domain cutover

1. Copy the currently authoritative DigitalOcean DNS records to Route 53 first.
2. Keep the old website records pointing to DigitalOcean while nameservers are changed.
3. Request ACM certificate in `us-east-1` for `yatoca.pe` and `www.yatoca.pe`.
4. Add ACM validation records to Route 53 (and, if validation is needed before delegation, also add the validation CNAME to the currently authoritative DNS provider).
5. Change registrar nameservers to the Route 53 delegation set only after all DNS records are verified.
6. Wait for ACM to become `ISSUED`.
7. Redeploy infrastructure with `CERTIFICATE_ARN=<arn>` so CloudFront accepts `yatoca.pe` and `www.yatoca.pe`.
8. Change only the website A/AAAA/WWW records in Route 53 to CloudFront aliases.
9. Verify web and mail before deleting DigitalOcean DNS/resources.

Never "clean up" mail-related DNS during the cutover. Cleanup is a separate post-migration task.
