data "aws_route53_zone" "base" {
  name = var.dns.base_domain_name
}

// create certificate in local account
resource "aws_acm_certificate" "acm_certificate" {
  provider          = aws.us-east-1 // cloudfront requires certificate in us-east-1
  domain_name       = var.dns.app_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

// add certificate validation in Route53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.base.zone_id
}

// successful validation of an ACM certificate
resource "aws_acm_certificate_validation" "validation" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

// create A record in base zone
resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.base.zone_id
  name    = var.dns.app_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2" // Hardcoded value for CloudFront
    evaluate_target_health = false
  }
}