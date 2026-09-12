# Yatoca portable Terraform

This Terraform definition is for **recovery into a new AWS account** or for a deliberate future account migration. It is not the owner of the currently running AWS resources.

Current production is managed by the existing CloudFormation/SAM stack plus a few resources that were created manually. Do not run `terraform apply` against the current production account unless you first import every overlapping resource and intentionally transfer ownership from CloudFormation to Terraform.

## Architecture reproduced

- private S3 static web bucket
- private S3 media bucket
- CloudFront OAC + bucket policies
- CloudFront Function for Next.js static-export route rewriting
- API Gateway HTTP API
- Lambda Node.js 22 arm64 function
- DynamoDB feedback table (`pk` + `sk`)
- ACM certificate in `us-east-1`
- Route 53 hosted zone
- current Google/TXT/DMARC/DKIM DNS records
- CloudFront production aliases when enabled
- optional empty CodeCommit repository

## Why the domain flow has three states

CloudFront alternate domain names are globally unique. A new distribution in another AWS account cannot simply claim `yatoca.pe` while the current production distribution still owns it.

Therefore the target distribution is built in three stages:

```text
1. default CloudFront certificate, no aliases
2. Yatoca ACM certificate attached, still no aliases
3. aliases declared only after the CloudFront alias move/release
```

Terraform variables model this explicitly:

```hcl
attach_custom_certificate = false
enable_custom_domain       = false
```

`enable_custom_domain=true` is rejected unless `attach_custom_certificate=true`.

## Phase 1 - build the new account

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Keep both domain flags `false`.

Terraform creates the certificate and outputs its DNS validation records while CloudFront remains usable on its default `*.cloudfront.net` hostname.

Publish the ACM validation CNAMEs in the **currently authoritative DNS** as well as leaving them in the new Route 53 zone. Wait for ACM `ISSUED`.

## Phase 2 - attach the certificate without claiming the aliases

Set:

```hcl
attach_custom_certificate = true
enable_custom_domain       = false
```

Then run:

```bash
terraform apply
```

Copy media and deploy the web build. Test the target `*.cloudfront.net` hostname.

For a cross-account CloudFront alias move, also publish the TXT ownership records shown by:

```bash
terraform output -json cloudfront_alias_transfer_verification_records
```

in the **currently authoritative DNS**.

## Phase 3 - move/release the CloudFront aliases

The existing source distribution already owns `yatoca.pe` and `www.yatoca.pe`. This is an AWS CloudFront control-plane operation, not a Route 53 operation.

For a planned cross-account move, follow the current AWS CloudFront "Move the alternate domain name" procedure. The `UpdateDomainAssociation` flow requires the source distribution to be disabled before a cross-account move. For an apex domain where a maintenance window is not acceptable, coordinate the move with AWS Support.

Do **not** set `enable_custom_domain=true` before this step; CloudFront will reject duplicate alternate domain names.

After the alias(es) have been transferred to the target distribution, set:

```hcl
attach_custom_certificate = true
enable_custom_domain       = true
```

and run `terraform apply` to reconcile Terraform state/configuration and create the new-zone Route 53 A/AAAA aliases.

## Phase 4 - DNS/account delegation

If the old Route 53 zone is still authoritative, point its apex and `www` records at the **new** CloudFront distribution immediately after the alias move, then verify production. This minimizes the alias-transfer maintenance window.

After that, change the registrar nameservers to the new Route 53 name servers. The new zone already contains the preserved mail/service DNS and the new CloudFront aliases.

See `../../docs/NEW_AWS_ACCOUNT_RECOVERY.md` for the full runbook.

## State

Terraform state is not committed. For an actual production recovery, use a remote encrypted backend (for example S3 with versioning and locking) before the environment becomes long-lived.
