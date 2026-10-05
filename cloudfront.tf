resource "aws_cloudfront_distribution" "site" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http1.1"
  price_class     = "PriceClass_All"
  aliases         = [var.domain_name, "www.${var.domain_name}"]
  tags = {
    Name = " Portfolio-website"
}

  origin {
    origin_id           = "ron-mercier101.com.s3.us-east-2.amazonaws.com-mc43t4ss663"
    domain_name         = "ron-mercier101.com.s3-website.us-east-2.amazonaws.com"
    connection_attempts = 3
    connection_timeout  = 10

    custom_header {
      name  = "referer"
      value = "https://www.ron-mercier101.com/*"
    }

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }

  default_cache_behavior {
    target_origin_id       = "ron-mercier101.com.s3.us-east-2.amazonaws.com-mc43t4ss663"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # managed: CachingOptimized
    origin_request_policy_id   = "acba4595-bd28-49b8-b9fe-13317c0390fa" # managed: AllViewerExceptHostHeader
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c" # managed: SimpleCORS
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
