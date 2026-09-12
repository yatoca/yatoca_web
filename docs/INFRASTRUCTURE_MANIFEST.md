# Infrastructure manifest

## Current production ownership

| Resource family | Current owner/source |
|---|---|
| S3 web/assets, API Gateway, Lambda, IAM, CloudFront, CloudFront Function/OAC | CloudFormation/SAM `infrastructure/template.yaml` |
| DynamoDB | originally created manually, referenced by CloudFormation Lambda |
| Route 53 hosted zone/records | originally created/staged manually |
| ACM certificate | originally requested/validated manually |
| Source repository | CodeCommit, separate from application stack |

## Portable Terraform ownership

The disaster-recovery Terraform definition intentionally includes **all** application infrastructure so a new account does not depend on undocumented manual resources.

| Terraform file | Resources |
|---|---|
| `s3.tf` | web/assets buckets, access controls, OAC bucket policies |
| `dynamodb.tf` | feedback table |
| `iam.tf` | Lambda execution role and permissions |
| `lambda.tf` | Lambda package/function |
| `api_gateway.tf` | HTTP API, routes, integration, permission |
| `acm.tf` | certificate and DNS validation |
| `route53.tf` | hosted zone, mail/service DNS, validation, CloudFront aliases |
| `cloudfront.tf` | distribution, origins/cache behaviors |
| `cloudfront_function.tf` | static-export path rewrite |
| `codecommit.tf` | optional empty CodeCommit repository |

Terraform state is intentionally excluded from Git.
