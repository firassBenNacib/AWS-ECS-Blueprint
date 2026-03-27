variable "alb_name" {
  description = "Backend ALB name base"
  type        = string
  default     = "app-backend-alb"
}

variable "alb_target_group_name" {
  description = "Backend ALB target group name base"
  type        = string
  default     = "app-backend-tg"
}

variable "alb_listener_port" {
  description = "Backend ALB primary listener port used by CloudFront origin traffic"
  type        = number
  default     = 443
}

variable "alb_certificate_arn" {
  description = "Regional ACM certificate ARN for the ALB HTTPS listener (can be imported from Let's Encrypt)"
  type        = string
  default     = null

  validation {
    condition     = var.alb_certificate_arn != null && trimspace(var.alb_certificate_arn) != ""
    error_message = "alb_certificate_arn must be set. HTTPS-only ALB mode requires a regional ACM certificate."
  }
}

variable "alb_ssl_policy" {
  description = "SSL policy for the ALB HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alb_health_check_matcher" {
  description = "ALB target group health check matcher"
  type        = string
  default     = "200-399"
}

variable "alb_health_check_interval_seconds" {
  description = "ALB target group health check interval (seconds)"
  type        = number
  default     = 30
}

variable "alb_health_check_timeout_seconds" {
  description = "ALB target group health check timeout (seconds)"
  type        = number
  default     = 5
}

variable "alb_health_check_healthy_threshold" {
  description = "ALB target group healthy threshold count"
  type        = number
  default     = 2
}

variable "alb_health_check_unhealthy_threshold" {
  description = "ALB target group unhealthy threshold count"
  type        = number
  default     = 3
}

variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection (required in this production-only configuration)"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.alb_idle_timeout >= 1 && var.alb_idle_timeout <= 4000 && var.alb_idle_timeout == floor(var.alb_idle_timeout)
    error_message = "alb_idle_timeout must be an integer between 1 and 4000."
  }
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb/"
}

variable "backend_origin_protocol_policy" {
  description = "CloudFront-to-backend origin protocol policy for the primary backend origin. Only HTTPS is supported."
  type        = string
  default     = "https-only"

  validation {
    condition     = var.backend_origin_protocol_policy == "https-only"
    error_message = "backend_origin_protocol_policy must be https-only."
  }
}

variable "backend_viewer_protocol_policy" {
  description = "Viewer protocol policy for backend CloudFront distribution"
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "redirect-to-https", "https-only"], var.backend_viewer_protocol_policy)
    error_message = "backend_viewer_protocol_policy must be one of allow-all, redirect-to-https, or https-only."
  }
}

variable "enable_origin_auth_header" {
  description = "Enable CloudFront origin custom-header authentication for backend origin protection"
  type        = bool
  default     = true
}

variable "origin_auth_header_name" {
  description = "Primary custom header name used for backend origin authentication"
  type        = string
  default     = "X-Origin-Verify"
}

variable "origin_auth_header_ssm_parameter_name" {
  description = "SSM SecureString parameter name containing the primary origin-auth header value."
  type        = string
  default     = ""

  validation {
    condition     = trimspace(var.origin_auth_header_ssm_parameter_name) == "" || startswith(trimspace(var.origin_auth_header_ssm_parameter_name), "/")
    error_message = "origin_auth_header_ssm_parameter_name must start with '/' when set."
  }
}

variable "origin_auth_previous_header_name" {
  description = "Secondary custom header name used during origin auth secret rotation"
  type        = string
  default     = "X-Origin-Verify-Prev"

  validation {
    condition     = trimspace(var.origin_auth_previous_header_name) != ""
    error_message = "origin_auth_previous_header_name must not be empty."
  }
}

variable "origin_auth_previous_header_ssm_parameter_name" {
  description = "Optional SSM SecureString parameter name containing the previous origin-auth header value for safe rotation windows."
  type        = string
  default     = ""

  validation {
    condition     = trimspace(var.origin_auth_previous_header_ssm_parameter_name) == "" || startswith(trimspace(var.origin_auth_previous_header_ssm_parameter_name), "/")
    error_message = "origin_auth_previous_header_ssm_parameter_name must start with '/' when set."
  }
}

variable "acm_cert_frontend" {
  description = "ACM certificate ARN for frontend CloudFront distribution (must be us-east-1)"
  type        = string
}

variable "backend_cache_policy_id" {
  description = "CloudFront cache policy ID for backend distribution"
  type        = string
  default     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

variable "backend_origin_request_policy_id" {
  description = "CloudFront origin request policy ID for backend distribution"
  type        = string
  default     = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}

variable "frontend_geo_restriction_type" {
  description = "Frontend CloudFront geo restriction mode: none, whitelist, or blacklist."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.frontend_geo_restriction_type)
    error_message = "frontend_geo_restriction_type must be one of none, whitelist, or blacklist."
  }
}

variable "frontend_geo_locations" {
  description = "ISO 3166-1 alpha-2 country codes used when frontend_geo_restriction_type is whitelist or blacklist."
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.frontend_geo_restriction_type == "none" ||
      length(var.frontend_geo_locations) > 0
    )
    error_message = "frontend_geo_locations must contain at least one country code when frontend_geo_restriction_type is whitelist or blacklist."
  }
}

variable "frontend_cache_policy_id" {
  description = "CloudFront cache policy ID for frontend distribution"
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "frontend_price_class" {
  description = "CloudFront price class for frontend distribution"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.frontend_price_class)
    error_message = "frontend_price_class must be one of PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "frontend_viewer_protocol_policy" {
  description = "Viewer protocol policy for frontend CloudFront distribution"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["allow-all", "redirect-to-https", "https-only"], var.frontend_viewer_protocol_policy)
    error_message = "frontend_viewer_protocol_policy must be one of allow-all, redirect-to-https, or https-only."
  }
}

variable "frontend_web_acl_arn" {
  description = "Optional WAFv2 Web ACL ARN for frontend CloudFront distribution"
  type        = string
  default     = null
}

variable "backend_web_acl_arn" {
  description = "Optional WAFv2 Web ACL ARN for backend CloudFront distribution"
  type        = string
  default     = null
}

variable "alb_web_acl_arn" {
  description = "Optional WAFv2 Web ACL ARN for backend ALB (regional)"
  type        = string
  default     = null
}

variable "enable_managed_waf" {
  description = "Create and attach default managed-rule WAF ACLs when explicit ARNs are not provided"
  type        = bool
  default     = true
}

variable "waf_rate_limit_requests_per_5_mins" {
  description = "WAF rate-limit threshold: maximum requests per 5 minutes per source IP before the rule blocks traffic."
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit_requests_per_5_mins >= 100
    error_message = "waf_rate_limit_requests_per_5_mins must be >= 100 (AWS WAF minimum)."
  }
}

variable "waf_log_retention_days" {
  description = "CloudWatch Logs retention for managed WAF ACL logs"
  type        = number
  default     = 365
}

variable "enable_cloudfront_access_logs" {
  description = "Enable CloudFront standard access logs for frontend and backend distributions"
  type        = bool
  default     = true
}

variable "enable_s3_access_logging" {
  description = "Enable S3 server access logging for primary S3 buckets"
  type        = bool
  default     = true
}

variable "cloudfront_logs_bucket_name" {
  description = "S3 bucket name used to store CloudFront access logs when enable_cloudfront_access_logs=true"
  type        = string
  default     = ""
}

variable "s3_access_logs_bucket_name" {
  description = "Optional dedicated S3 bucket name for server access logs. When empty, an environment-aware default name is generated."
  type        = string
  default     = ""
}

variable "dr_frontend_bucket_name" {
  description = "Optional DR replica bucket name for frontend content. When empty, an environment-aware default name is generated."
  type        = string
  default     = ""
}

variable "dr_cloudfront_logs_bucket_name" {
  description = "Optional DR replica bucket name for CloudFront logs. When empty, an environment-aware default name is generated."
  type        = string
  default     = ""
}

variable "cloudfront_logs_prefix" {
  description = "Prefix for CloudFront access logs objects"
  type        = string
  default     = "cloudfront/"
}

variable "enable_cloudfront_logs_lifecycle" {
  description = "Enable lifecycle expiration for CloudFront access logs bucket when logs are enabled"
  type        = bool
  default     = true
}

variable "cloudfront_logs_expiration_days" {
  description = "Expire CloudFront access log objects after this many days"
  type        = number
  default     = 90

  validation {
    condition     = var.cloudfront_logs_expiration_days >= 1 && var.cloudfront_logs_expiration_days == floor(var.cloudfront_logs_expiration_days)
    error_message = "cloudfront_logs_expiration_days must be an integer >= 1."
  }
}

variable "cloudfront_logs_abort_incomplete_multipart_upload_days" {
  description = "Abort incomplete multipart uploads in CloudFront logs bucket after this many days"
  type        = number
  default     = 7

  validation {
    condition     = var.cloudfront_logs_abort_incomplete_multipart_upload_days >= 1 && var.cloudfront_logs_abort_incomplete_multipart_upload_days == floor(var.cloudfront_logs_abort_incomplete_multipart_upload_days)
    error_message = "cloudfront_logs_abort_incomplete_multipart_upload_days must be an integer >= 1."
  }
}
