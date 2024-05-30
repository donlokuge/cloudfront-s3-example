locals {
  use_default_acm_certificate = var.dns.app_domain_name == ""
  minimum_protocol_version    = local.use_default_acm_certificate ? "TLSv1" : "TLSv1.2_2021"
  acm_certificate_arn         = local.use_default_acm_certificate ? "" : aws_acm_certificate.acm_certificate.arn
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  comment = "Static Website Distribution"

  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  wait_for_deployment = false
  aliases             = var.dns.app_domain_name != "" ? [var.dns.app_domain_name] : null

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    compress               = true
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 3600

    forwarded_values {
      headers      = ["Authorization", "Origin"]
      query_string = true

      cookies {
        forward = "none"
      }
    }

  }

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = local.acm_certificate_arn
    ssl_support_method             = local.use_default_acm_certificate ? null : "sni-only"
    minimum_protocol_version       = local.minimum_protocol_version
    cloudfront_default_certificate = local.use_default_acm_certificate
  }

  depends_on = [aws_s3_bucket.website_bucket]
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "access-identity-${aws_s3_bucket.website_bucket.id}.s3.amazonaws.com"
}