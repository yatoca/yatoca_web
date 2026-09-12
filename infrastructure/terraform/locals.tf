data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  www_domain = "www.${var.domain_name}"

  web_bucket_name = coalesce(
    var.web_bucket_name,
    "${var.project_name}-web-${data.aws_caller_identity.current.account_id}"
  )

  assets_bucket_name = coalesce(
    var.assets_bucket_name,
    "${var.project_name}-assets-${data.aws_caller_identity.current.account_id}"
  )

  hosted_zone_id = var.create_hosted_zone ? aws_route53_zone.primary[0].zone_id : var.existing_hosted_zone_id

  # Preserve current public mail/service records exactly during account moves.
  google_mx = [
    "1 aspmx.l.google.com.",
    "3 alt2.aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "8 alt3.aspmx.l.google.com.",
    "8 alt4.aspmx.l.google.com.",
  ]

  apex_txt = [
    "\"google-site-verification=iSQT41lsnYz-EALupDo9IJaspvaTSF7kd7wQEQm2gtk\"",
    "\"T4409132\"",
    "\"v=spf1 include:secureserver.net -all\"",
  ]
}
