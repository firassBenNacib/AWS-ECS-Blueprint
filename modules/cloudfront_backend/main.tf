locals {
  environment_name = (
    var.environment_name_override != null && trimspace(var.environment_name_override) != ""
  ) ? trimspace(var.environment_name_override) : terraform.workspace
  environment_tag = var.enable_environment_suffix ? (
    local.environment_name == "prod" ? "Prod" : local.environment_name == "nonprod" ? "Stage" : title(local.environment_name)
  ) : "Default"
  use_origin_group = var.enable_origin_failover && (
    trimspace(var.backend_failover_domain_name) != "" &&
    trimspace(var.backend_failover_domain_name) != trimspace(var.backend_domain_name)
  ) && length(setsubtract(var.allowed_methods, ["GET", "HEAD", "OPTIONS"])) == 0
}

resource "aws_cloudfront_distribution" "backend" {
  #checkov:skip=CKV_AWS_305: API distribution does not use a static default root object.
  #checkov:skip=CKV2_AWS_46: This control applies to S3 origins; backend origin is a custom ALB origin.
  #checkov:skip=CKV2_AWS_47: WAF ACL with Log4j mitigation rules is attached in the root module.
  #checkov:skip=CKV2_AWS_32: Security response headers policy is attached in default_cache_behavior.
  origin {
    domain_name = var.backend_domain_name
    origin_id   = "backend-alb-origin"

    dynamic "custom_origin_config" {
      for_each = var.backend_vpc_origin_id == null || trimspace(var.backend_vpc_origin_id) == "" ? [1] : []
      content {
        http_port              = var.app_port
        origin_protocol_policy = var.origin_protocol_policy
        https_port             = 443
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }

    dynamic "vpc_origin_config" {
      for_each = var.backend_vpc_origin_id != null && trimspace(var.backend_vpc_origin_id) != "" ? [1] : []
      content {
        vpc_origin_id = var.backend_vpc_origin_id
      }
    }

    dynamic "custom_header" {
      for_each = var.enable_origin_auth_header && var.origin_auth_header_value != "" ? [1] : []
      content {
        name  = var.origin_auth_header_name
        value = var.origin_auth_header_value
      }
    }

    dynamic "custom_header" {
      for_each = var.enable_origin_auth_header && var.origin_auth_previous_header_value != "" ? [1] : []
      content {
        name  = var.origin_auth_previous_header_name
        value = var.origin_auth_previous_header_value
      }
    }
  }

  dynamic "origin" {
    for_each = local.use_origin_group ? [1] : []
    content {
      domain_name = var.backend_failover_domain_name
      origin_id   = "backend-alb-origin-dr"

      custom_origin_config {
        http_port              = var.app_port
        origin_protocol_policy = var.backend_failover_protocol_policy
        https_port             = 443
        origin_ssl_protocols   = ["TLSv1.2"]
      }

      dynamic "custom_header" {
        for_each = var.enable_origin_auth_header && var.origin_auth_header_value != "" ? [1] : []
        content {
          name  = var.origin_auth_header_name
          value = var.origin_auth_header_value
        }
      }

      dynamic "custom_header" {
        for_each = var.enable_origin_auth_header && var.origin_auth_previous_header_value != "" ? [1] : []
        content {
          name  = var.origin_auth_previous_header_name
          value = var.origin_auth_previous_header_value
        }
      }
    }
  }

  dynamic "origin_group" {
    for_each = local.use_origin_group ? [1] : []
    content {
      origin_id = "backend-origin-group"

      failover_criteria {
        status_codes = [500, 502, 503, 504]
      }

      member {
        origin_id = "backend-alb-origin"
      }

      member {
        origin_id = "backend-alb-origin-dr"
      }
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = var.price_class
  web_acl_id      = var.web_acl_id
  comment         = var.enable_environment_suffix ? "CloudFront Distribution for Backend API (${local.environment_tag})" : "CloudFront Distribution for Backend API"
  aliases         = [var.backend_alias]

  logging_config {
    bucket          = var.access_logs_bucket
    include_cookies = false
    prefix          = var.access_logs_prefix
  }

  default_cache_behavior {
    target_origin_id           = local.use_origin_group ? "backend-origin-group" : "backend-alb-origin"
    viewer_protocol_policy     = var.viewer_protocol_policy
    allowed_methods            = var.allowed_methods
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = var.cache_policy_id
    compress                   = true
    origin_request_policy_id   = var.origin_request_policy_id
    response_headers_policy_id = var.response_headers_policy_id
  }

  viewer_certificate {
    acm_certificate_arn      = var.backend_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_type == "none" ? [] : var.geo_locations
    }
  }

  tags = {
    Name        = var.enable_environment_suffix ? "cloudfront-backend-${local.environment_name}" : "cloudfront-backend"
    Environment = local.environment_tag
  }
}
