resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = [local.www_domain]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Validation waiting is intentionally enabled only when the custom certificate
# is being attached. During a new-account move, publish these CNAMEs in the
# currently authoritative DNS first, wait for ISSUED, then set
# attach_custom_certificate=true.
resource "aws_acm_certificate_validation" "site" {
  count    = var.attach_custom_certificate ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
