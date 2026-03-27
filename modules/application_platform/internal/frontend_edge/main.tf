resource "aws_cloudfront_response_headers_policy" "secure_defaults" {
  name    = "${var.environment.project_name}-${var.environment.name}-secure-headers"
  comment = "Security headers for the ${var.environment.name} CloudFront distribution."

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; base-uri 'self'; connect-src 'self' https:; font-src 'self' data: https:; frame-ancestors 'self'; img-src 'self' data: https:; object-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; upgrade-insecure-requests"
      override                = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), geolocation=(), microphone=()"
      override = true
    }

    items {
      header   = "Cross-Origin-Embedder-Policy"
      value    = "unsafe-none"
      override = true
    }

    items {
      header   = "Cross-Origin-Opener-Policy"
      value    = "same-origin-allow-popups"
      override = true
    }

    items {
      header   = "Cross-Origin-Resource-Policy"
      value    = "same-site"
      override = true
    }
  }

  remove_headers_config {
    items { header = "Server" }
    items { header = "X-Amz-Replication-Status" }
    items { header = "X-Amz-Server-Side-Encryption" }
    items { header = "X-Amz-Server-Side-Encryption-Aws-Kms-Key-Id" }
    items { header = "X-Amz-Version-Id" }
  }
}

module "cloudfront_frontend" {
  source = "../../../cloudfront_frontend"

  frontend_bucket_domain                    = var.frontend.bucket_domain
  secondary_bucket_domain                   = var.frontend.secondary_bucket_domain
  frontend_aliases                          = var.frontend.aliases
  frontend_cert_arn                         = var.frontend.cert_arn
  cache_policy_id                           = var.frontend.cache_policy_id
  price_class                               = var.frontend.price_class
  response_headers_policy_id                = aws_cloudfront_response_headers_policy.secure_defaults.id
  viewer_protocol_policy                    = var.frontend.viewer_protocol_policy
  geo_restriction_type                      = var.frontend.geo_restriction_type
  geo_locations                             = var.frontend.geo_locations
  access_logs_bucket                        = var.frontend.access_logs_bucket
  access_logs_prefix                        = var.frontend.access_logs_prefix
  enable_environment_suffix                 = var.environment.enable_suffix
  environment_domain                        = var.environment.domain
  environment_name_override                 = var.environment.name
  web_acl_id                                = var.web_acl_id
  enable_spa_routing                        = var.frontend.runtime_mode == "s3"
  backend_origin_enabled                    = var.backend.origin_enabled
  backend_origin_domain_name                = var.backend.origin_domain_name
  backend_origin_vpc_origin_id              = var.backend.origin_vpc_origin_id
  backend_origin_https_port                 = var.backend.origin_https_port
  backend_origin_protocol_policy            = var.backend.origin_protocol_policy
  backend_viewer_protocol_policy            = var.backend.viewer_protocol_policy
  backend_cache_policy_id                   = var.backend.cache_policy_id
  backend_origin_request_policy_id          = var.backend.origin_request_policy_id
  backend_response_headers_policy_id        = aws_cloudfront_response_headers_policy.secure_defaults.id
  backend_allowed_methods                   = var.backend.allowed_methods
  backend_path_patterns                     = var.backend.path_patterns
  backend_origin_auth_enabled               = var.backend.origin_auth_enabled
  backend_origin_auth_header_name           = var.backend.origin_auth_header_name
  backend_origin_auth_header_value          = var.backend.origin_auth_header_value
  backend_origin_auth_previous_header_name  = var.backend.origin_auth_previous_header_name
  backend_origin_auth_previous_header_value = var.backend.origin_auth_previous_header_value
  frontend_runtime_mode                     = var.frontend.runtime_mode
  frontend_alb_domain_name                  = var.frontend.alb_domain_name
  frontend_vpc_origin_id                    = var.frontend.vpc_origin_id
  frontend_alb_https_port                   = var.frontend.alb_https_port
}

resource "aws_route53_record" "frontend_root" {
  allow_overwrite = true
  zone_id         = var.route53_zone_id_effective
  name            = var.frontend.aliases[0]
  type            = "A"

  alias {
    name                   = module.cloudfront_frontend.frontend_url
    zone_id                = module.cloudfront_frontend.frontend_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "frontend_www" {
  count           = length(var.frontend.aliases) > 1 ? 1 : 0
  allow_overwrite = true
  zone_id         = var.route53_zone_id_effective
  name            = var.frontend.aliases[count.index + 1]
  type            = "A"

  alias {
    name                   = module.cloudfront_frontend.frontend_url
    zone_id                = module.cloudfront_frontend.frontend_hosted_zone_id
    evaluate_target_health = false
  }
}
