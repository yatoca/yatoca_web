variable "aws_region" {
  description = "Primary application region. Current production uses us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "codecommit_region" {
  description = "Region for the optional CodeCommit repository."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefix used for account-portable resource names."
  type        = string
  default     = "yatoca"
}

variable "domain_name" {
  description = "Production apex domain."
  type        = string
  default     = "yatoca.pe"
}

variable "feedback_table_name" {
  description = "DynamoDB table for new website feedback submissions."
  type        = string
  default     = "yatoca-feedback"
}

variable "web_bucket_name" {
  description = "Optional explicit globally unique web bucket name. Null derives yatoca-web-<account-id>."
  type        = string
  default     = null
  nullable    = true
}

variable "assets_bucket_name" {
  description = "Optional explicit globally unique assets bucket name. Null derives yatoca-assets-<account-id>."
  type        = string
  default     = null
  nullable    = true
}

variable "backup_bucket_name" {
  description = "Optional explicit globally unique recovery backup bucket name. Null derives yatoca-backups-<account-id>."
  type        = string
  default     = null
  nullable    = true
}

variable "budget_email" {
  description = "Optional email address for the USD 5/month AWS Budget alerts. Null skips budget creation."
  type        = string
  default     = null
  nullable    = true
}

variable "monthly_budget_usd" {
  description = "Monthly Yatoca AWS cost target in USD."
  type        = number
  default     = 5

  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "monthly_budget_usd must be greater than zero."
  }
}

variable "create_hosted_zone" {
  description = "Create a new Route 53 hosted zone. Use true for a new-account recovery."
  type        = bool
  default     = true
}

variable "existing_hosted_zone_id" {
  description = "Existing hosted zone ID when create_hosted_zone=false."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.create_hosted_zone || try(trimspace(var.existing_hosted_zone_id) != "", false)
    error_message = "existing_hosted_zone_id must be provided when create_hosted_zone=false."
  }
}

variable "attach_custom_certificate" {
  description = "Attach the issued ACM certificate to the target CloudFront distribution without claiming the aliases yet. Use this before a cross-account alias move."
  type        = bool
  default     = false
}

variable "enable_custom_domain" {
  description = "Declare yatoca.pe/www as CloudFront aliases and create Route 53 aliases. In a cross-account move, enable only after the CloudFront aliases have been transferred/released from the source distribution."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_custom_domain || var.attach_custom_certificate
    error_message = "enable_custom_domain=true requires attach_custom_certificate=true."
  }
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. Current production uses PriceClass_100."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be PriceClass_100, PriceClass_200 or PriceClass_All."
  }
}

variable "enable_codecommit" {
  description = "Create an empty CodeCommit repository. Disabled by default; source content must be pushed separately."
  type        = bool
  default     = false
}

variable "codecommit_repository_name" {
  description = "Optional CodeCommit repository name."
  type        = string
  default     = "yatoca-web"
}
