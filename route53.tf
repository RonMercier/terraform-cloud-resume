data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "apex" {
  for_each = toset(["A", "AAAA"])

  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = each.value

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  for_each = toset(["A", "AAAA"])

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = each.value

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "acm_validation_main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_ec94762fcde94baefb6c0a8bd9ebcd7b.ron-mercier101.com"
  type    = "CNAME"
  ttl     = 300
  records = ["_223fdfd08f6d9baa48627423aec7842c.xlfgrmvvlj.acm-validations.aws."]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "acm_validation_doubled" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_68a93cfc6e793584e86e19c87fbed865.ron-mercier101.com.ron-mercier101.com"
  type    = "CNAME"
  ttl     = 300
  records = ["_635f189038c32946487352f62491f1cd.xlfgrmvvlj.acm-validations.aws."]

  lifecycle {
    prevent_destroy = true
  }
}
