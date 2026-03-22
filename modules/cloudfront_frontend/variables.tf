variable "frontend_bucket_domain" {
  description = "S3 bucket domain name"
  type        = string
  default     = ""
}

variable "secondary_bucket_domain" {
  description = "DR S3 bucket domain name used as secondary origin for CloudFront failover"
  type        = string
  default     = ""
}

variable "frontend_aliases" {
  description = "Frontend aliases for CloudFront"
  type        = list(string)
}

variable "frontend_cert_arn" {
  description = "ACM certificate ARN for frontend"
  type        = string
}

variable "cache_policy_id" {
  description = "CloudFront cache policy ID"
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be one of PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "response_headers_policy_id" {
  description = "CloudFront response headers policy ID"
  type        = string
  default     = "67f7725c-6f97-4210-82d7-5512b31e9d03"
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy for the frontend distribution default cache behavior"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["allow-all", "redirect-to-https", "https-only"], var.viewer_protocol_policy)
    error_message = "viewer_protocol_policy must be one of allow-all, redirect-to-https, or https-only."
  }
}

variable "access_logs_bucket" {
  description = "S3 bucket domain name for CloudFront logs (for example bucket.s3.amazonaws.com)"
  type        = string

  validation {
    condition     = trimspace(var.access_logs_bucket) != ""
    error_message = "access_logs_bucket must not be empty."
  }
}

variable "access_logs_prefix" {
  description = "Prefix used for frontend CloudFront log objects"
  type        = string
  default     = "cloudfront/frontend/"
}

variable "enable_environment_suffix" {
  description = "Suffix frontend aliases and tags with environment"
  type        = bool
  default     = false
}

variable "environment_domain" {
  description = "Base domain used to derive environment aliases"
  type        = string
  default     = ""
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for naming and alias derivation. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}

variable "geo_restriction_type" {
  description = "CloudFront geo restriction mode for the frontend distribution: none, whitelist, or blacklist."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type must be one of none, whitelist, or blacklist."
  }
}

variable "geo_locations" {
  description = "ISO 3166-1 alpha-2 country codes used when geo_restriction_type is whitelist or blacklist."
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.geo_restriction_type == "none" ||
      length(var.geo_locations) > 0
    )
    error_message = "geo_locations must contain at least one country code when geo_restriction_type is whitelist or blacklist."
  }
}

variable "web_acl_id" {
  description = "Optional WAFv2 Web ACL ARN"
  type        = string
  default     = null
}

variable "frontend_runtime_mode" {
  description = "Frontend runtime mode: s3 (S3+CloudFront) or ecs (CloudFront to ALB/ECS)."
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "ecs"], var.frontend_runtime_mode)
    error_message = "frontend_runtime_mode must be one of s3 or ecs."
  }
}

variable "frontend_alb_domain_name" {
  description = "ALB domain name used as frontend origin when frontend_runtime_mode=ecs."
  type        = string
  default     = ""
}

variable "frontend_vpc_origin_id" {
  description = "Optional CloudFront VPC origin ID for the frontend ALB origin when frontend_runtime_mode=ecs."
  type        = string
  default     = null
}

variable "frontend_alb_https_port" {
  description = "Frontend ALB HTTPS listener port when frontend_runtime_mode=ecs."
  type        = number
  default     = 443
}

variable "enable_spa_routing" {
  description = "Rewrite non-asset frontend routes to /index.html at the edge so SPA deep links work without affecting API paths."
  type        = bool
  default     = true
}

variable "backend_origin_enabled" {
  description = "When true, add a private ALB origin and ordered cache behaviors for backend/API paths."
  type        = bool
  default     = false
}

variable "backend_origin_domain_name" {
  description = "ALB domain name used as the backend origin when backend_origin_enabled=true."
  type        = string
  default     = ""
}

variable "backend_origin_vpc_origin_id" {
  description = "Optional CloudFront VPC origin ID for the backend ALB origin."
  type        = string
  default     = null
}

variable "backend_origin_https_port" {
  description = "Backend ALB listener port exposed to CloudFront."
  type        = number
  default     = 443
}

variable "backend_origin_protocol_policy" {
  description = "CloudFront-to-backend origin protocol policy."
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only"], var.backend_origin_protocol_policy)
    error_message = "backend_origin_protocol_policy must be one of http-only or https-only."
  }
}

variable "backend_viewer_protocol_policy" {
  description = "Viewer protocol policy for backend/API path cache behaviors."
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["allow-all", "redirect-to-https", "https-only"], var.backend_viewer_protocol_policy)
    error_message = "backend_viewer_protocol_policy must be one of allow-all, redirect-to-https, or https-only."
  }
}

variable "backend_cache_policy_id" {
  description = "CloudFront cache policy ID for backend/API path behaviors."
  type        = string
  default     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

variable "backend_origin_request_policy_id" {
  description = "CloudFront origin request policy ID for backend/API path behaviors."
  type        = string
  default     = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}

variable "backend_response_headers_policy_id" {
  description = "CloudFront response headers policy ID for backend/API path behaviors."
  type        = string
  default     = "67f7725c-6f97-4210-82d7-5512b31e9d03"
}

variable "backend_allowed_methods" {
  description = "HTTP methods accepted for backend/API path behaviors."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]

  validation {
    condition = alltrue([
      for method in var.backend_allowed_methods :
      contains(["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"], method)
    ])
    error_message = "backend_allowed_methods may contain only GET, HEAD, OPTIONS, PUT, POST, PATCH, and DELETE."
  }
}

variable "backend_path_patterns" {
  description = "Ordered cache behavior path patterns routed to the private backend origin."
  type        = list(string)
  default     = ["/api/*", "/auth/*", "/audit/*", "/notify/*", "/mailer/*", "/gateway/*"]
}

variable "backend_origin_auth_enabled" {
  description = "Attach custom origin-auth headers to the backend origin."
  type        = bool
  default     = true
}

variable "backend_origin_auth_header_name" {
  description = "Primary custom header name used to authenticate CloudFront to the backend origin."
  type        = string
  default     = "X-Origin-Verify"
}

variable "backend_origin_auth_header_value" {
  description = "Primary custom header value used to authenticate CloudFront to the backend origin."
  type        = string
  default     = ""
  sensitive   = true
}

variable "backend_origin_auth_previous_header_name" {
  description = "Secondary custom header name used during backend origin-auth rotation."
  type        = string
  default     = "X-Origin-Verify-Prev"
}

variable "backend_origin_auth_previous_header_value" {
  description = "Secondary custom header value used during backend origin-auth rotation."
  type        = string
  default     = ""
  sensitive   = true
}
