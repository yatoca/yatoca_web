resource "aws_route53_zone" "primary" {
  count = var.create_hosted_zone ? 1 : 0
  name  = var.domain_name
}

resource "aws_route53_record" "mx" {
  zone_id = local.hosted_zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 14400
  records = local.google_mx
}

resource "aws_route53_record" "apex_txt" {
  zone_id = local.hosted_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 3600
  records = local.apex_txt
}

resource "aws_route53_record" "dmarc" {
  zone_id = local.hosted_zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600
  records = ["\"v=DMARC1; p=quarantine; rua=mailto:postmaster@${var.domain_name}; pct=100\""]
}

resource "aws_route53_record" "mailchimp_k2" {
  zone_id = local.hosted_zone_id
  name    = "k2._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["dkim2.mcsv.net."]
}

resource "aws_route53_record" "mailchimp_k3" {
  zone_id = local.hosted_zone_id
  name    = "k3._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["dkim3.mcsv.net."]
}

resource "aws_route53_record" "titan_s1" {
  zone_id = local.hosted_zone_id
  name    = "s1._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 43200
  records = ["s1.domainkey.titan.email."]
}

resource "aws_route53_record" "titan_s2" {
  zone_id = local.hosted_zone_id
  name    = "s2._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 43200
  records = ["s2.domainkey.titan.email."]
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = local.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_route53_record" "apex_a" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.hosted_zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.hosted_zone_id
  name    = local.www_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.hosted_zone_id
  name    = local.www_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
