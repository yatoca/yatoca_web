output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "web_bucket_name" {
  value = aws_s3_bucket.web.bucket
}

output "assets_bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "backup_bucket_name" {
  value = aws_s3_bucket.backups.bucket
}

output "feedback_table_name" {
  value = aws_dynamodb_table.feedback.name
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.feedback.api_endpoint
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "hosted_zone_id" {
  value = local.hosted_zone_id
}

output "route53_name_servers" {
  value = var.create_hosted_zone ? aws_route53_zone.primary[0].name_servers : []
}

output "certificate_arn" {
  value = aws_acm_certificate.site.arn
}

output "acm_validation_records" {
  value = {
    for domain, record in aws_route53_record.acm_validation : domain => {
      name  = record.name
      type  = record.type
      value = one(record.records)
    }
  }
}


output "cloudfront_alias_transfer_verification_records" {
  description = "For a cross-account CloudFront alias move, publish these TXT records in the CURRENTLY authoritative DNS before moving the aliases."
  value = {
    apex = {
      name  = "_.${var.domain_name}"
      type  = "TXT"
      value = aws_cloudfront_distribution.site.domain_name
    }
    www = {
      name  = "_${local.www_domain}"
      type  = "TXT"
      value = aws_cloudfront_distribution.site.domain_name
    }
  }
}

output "codecommit_clone_url_http" {
  value = var.enable_codecommit ? aws_codecommit_repository.source[0].clone_url_http : null
}

output "codecommit_clone_url_ssh" {
  value = var.enable_codecommit ? aws_codecommit_repository.source[0].clone_url_ssh : null
}

output "monthly_budget_name" {
  value = var.budget_email == null ? null : aws_budgets_budget.monthly[0].name
}
