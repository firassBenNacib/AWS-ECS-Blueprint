locals {
  environment_name = (
    var.environment_name_override != null && trimspace(var.environment_name_override) != ""
  ) ? trimspace(var.environment_name_override) : terraform.workspace
  is_prod = local.environment_name == "prod"

  frontend_aliases_final = var.enable_environment_suffix && var.environment_domain != "" ? (
    local.is_prod ? [var.environment_domain, "www.${var.environment_domain}"] : ["${local.environment_name}.${var.environment_domain}", "www.${local.environment_name}.${var.environment_domain}"]
  ) : var.frontend_aliases

  environment_tag = var.enable_environment_suffix ? upper(local.environment_name) : "DEFAULT"
  oac_name = var.enable_environment_suffix ? format(
    "frontend-oac-%s-%s",
    local.environment_name,
    substr(sha1("${var.frontend_bucket_domain}:${var.secondary_bucket_domain}"), 0, 8)
    ) : format(
    "frontend-oac-%s",
    substr(sha1("${var.frontend_bucket_domain}:${var.secondary_bucket_domain}"), 0, 8)
  )

  use_s3                 = var.frontend_runtime_mode == "s3"
  use_ecs                = var.frontend_runtime_mode == "ecs"
  backend_origin_enabled = var.backend_origin_enabled
  backend_path_patterns_final = distinct([
    for pattern in var.backend_path_patterns :
    trimspace(pattern)
    if trimspace(pattern) != ""
  ])
  backend_path_prefixes = distinct([
    for pattern in local.backend_path_patterns_final :
    trimsuffix(pattern, "*")
  ])
}

resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = local.oac_name
  description                       = "Origin Access Control for CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "spa_request_rewrite" {
  count = var.enable_spa_routing ? 1 : 0

  name    = var.enable_environment_suffix ? "frontend-spa-rewrite-${local.environment_name}" : "frontend-spa-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite SPA viewer requests to /index.html without touching API paths."
  publish = true
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri || "/";
      var passthroughPrefixes = ${jsonencode(local.backend_path_prefixes)};

      for (var i = 0; i < passthroughPrefixes.length; i++) {
        if (passthroughPrefixes[i] && uri.indexOf(passthroughPrefixes[i]) === 0) {
          return request;
        }
      }

      if (uri === "/" || uri === "") {
        request.uri = "/index.html";
        return request;
      }

      if (uri.indexOf(".") === -1) {
        request.uri = "/index.html";
      }

      return request;
    }
  EOF
}

resource "aws_cloudfront_distribution" "frontend" {
  #checkov:skip=CKV2_AWS_32: Response headers policy is attached in default_cache_behavior; this can be a false positive in module graph scans.
  #checkov:skip=CKV2_AWS_47: WAF ACL with Log4j mitigation rules is attached in the root module.

  dynamic "origin" {
    for_each = local.use_s3 ? [1] : []
    content {
      domain_name              = var.frontend_bucket_domain
      origin_id                = "S3-frontend-origin"
      origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
    }
  }

  dynamic "origin" {
    for_each = local.use_s3 ? [1] : []
    content {
      domain_name              = var.secondary_bucket_domain
      origin_id                = "S3-frontend-origin-dr"
      origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
    }
  }

  dynamic "origin_group" {
    for_each = local.use_s3 ? [1] : []
    content {
      origin_id = "frontend-origin-group"

      failover_criteria {
        status_codes = [500, 502, 503, 504]
      }

      member {
        origin_id = "S3-frontend-origin"
      }

      member {
        origin_id = "S3-frontend-origin-dr"
      }
    }
  }

  dynamic "origin" {
    for_each = local.use_ecs ? [1] : []
    content {
      domain_name = var.frontend_alb_domain_name
      origin_id   = "frontend-alb-origin"

      dynamic "vpc_origin_config" {
        for_each = var.frontend_vpc_origin_id != null && trimspace(var.frontend_vpc_origin_id) != "" ? [1] : []
        content {
          vpc_origin_id = var.frontend_vpc_origin_id
        }
      }

      dynamic "custom_origin_config" {
        for_each = var.frontend_vpc_origin_id == null || trimspace(var.frontend_vpc_origin_id) == "" ? [1] : []
        content {
          http_port              = 80
          https_port             = var.frontend_alb_https_port
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    }
  }

  dynamic "origin" {
    for_each = local.backend_origin_enabled ? [1] : []
    content {
      domain_name = var.backend_origin_domain_name
      origin_id   = "backend-alb-origin"

      dynamic "custom_header" {
        for_each = var.backend_origin_auth_enabled && trimspace(var.backend_origin_auth_header_value) != "" ? [1] : []
        content {
          name  = var.backend_origin_auth_header_name
          value = var.backend_origin_auth_header_value
        }
      }

      dynamic "custom_header" {
        for_each = var.backend_origin_auth_enabled && trimspace(var.backend_origin_auth_previous_header_value) != "" ? [1] : []
        content {
          name  = var.backend_origin_auth_previous_header_name
          value = var.backend_origin_auth_previous_header_value
        }
      }

      dynamic "vpc_origin_config" {
        for_each = var.backend_origin_vpc_origin_id != null && trimspace(var.backend_origin_vpc_origin_id) != "" ? [1] : []
        content {
          vpc_origin_id = var.backend_origin_vpc_origin_id
        }
      }

      dynamic "custom_origin_config" {
        for_each = var.backend_origin_vpc_origin_id == null || trimspace(var.backend_origin_vpc_origin_id) == "" ? [1] : []
        content {
          http_port              = 80
          https_port             = var.backend_origin_https_port
          origin_protocol_policy = var.backend_origin_protocol_policy
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.price_class
  web_acl_id          = var.web_acl_id
  comment             = var.enable_environment_suffix ? "CloudFront Distribution for Frontend (${local.environment_tag})" : "CloudFront Distribution for Frontend"
  aliases             = local.frontend_aliases_final

  logging_config {
    bucket          = var.access_logs_bucket
    include_cookies = false
    prefix          = var.access_logs_prefix
  }

  default_cache_behavior {
    target_origin_id           = local.use_s3 ? "frontend-origin-group" : "frontend-alb-origin"
    viewer_protocol_policy     = var.viewer_protocol_policy
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = var.cache_policy_id
    response_headers_policy_id = var.response_headers_policy_id
    compress                   = true

    dynamic "function_association" {
      for_each = var.enable_spa_routing ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.spa_request_rewrite[0].arn
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.backend_origin_enabled ? toset(local.backend_path_patterns_final) : toset([])
    content {
      path_pattern               = ordered_cache_behavior.value
      target_origin_id           = "backend-alb-origin"
      viewer_protocol_policy     = var.backend_viewer_protocol_policy
      allowed_methods            = var.backend_allowed_methods
      cached_methods             = ["GET", "HEAD", "OPTIONS"]
      cache_policy_id            = var.backend_cache_policy_id
      origin_request_policy_id   = var.backend_origin_request_policy_id
      response_headers_policy_id = var.backend_response_headers_policy_id
      compress                   = true
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.frontend_cert_arn
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
    Name        = var.enable_environment_suffix ? "cloudfront-frontend-${local.environment_name}" : "cloudfront-frontend"
    Environment = local.environment_tag
  }
}
