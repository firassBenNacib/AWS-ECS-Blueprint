variable "backend_domain_name" {
  description = "Primary backend origin domain name"
  type        = string
}

variable "backend_vpc_origin_id" {
  description = "Optional CloudFront VPC origin ID for the primary backend origin."
  type        = string
  default     = null
}

variable "backend_failover_domain_name" {
  description = "Secondary backend origin domain name used for CloudFront origin failover"
  type        = string
}

variable "backend_alias" {
  description = "Alias for backend CloudFront"
  type        = string
}

variable "backend_cert_arn" {
  description = "ACM certificate ARN for backend"
  type        = string
}

variable "cache_policy_id" {
  description = "CloudFront cache policy ID"
  type        = string
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

variable "origin_request_policy_id" {
  description = "CloudFront origin request policy ID"
  type        = string
}

variable "response_headers_policy_id" {
  description = "Response headers policy ID for backend default cache behavior"
  type        = string
  default     = "67f7725c-6f97-4210-82d7-5512b31e9d03"
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy for the backend distribution default cache behavior"
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "redirect-to-https", "https-only"], var.viewer_protocol_policy)
    error_message = "viewer_protocol_policy must be one of allow-all, redirect-to-https, or https-only."
  }
}

variable "app_port" {
  description = "Backend ALB listener port used by CloudFront origin"
  type        = number
  default     = 8080
}

variable "origin_protocol_policy" {
  description = "CloudFront-to-origin protocol policy"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only"], var.origin_protocol_policy)
    error_message = "origin_protocol_policy must be either 'http-only' or 'https-only'."
  }
}

variable "backend_failover_protocol_policy" {
  description = "CloudFront-to-secondary-origin protocol policy"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only"], var.backend_failover_protocol_policy)
    error_message = "backend_failover_protocol_policy must be either 'http-only' or 'https-only'."
  }
}

variable "enable_origin_failover" {
  description = "Enable CloudFront origin-group failover when the backend is read-only. Mutating API methods automatically disable origin groups."
  type        = bool
  default     = false
}

variable "allowed_methods" {
  description = "HTTP methods accepted by the backend distribution."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]

  validation {
    condition = alltrue([
      for method in var.allowed_methods :
      contains(["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"], method)
    ])
    error_message = "allowed_methods may contain only GET, HEAD, OPTIONS, PUT, POST, PATCH, and DELETE."
  }
}

variable "geo_restriction_type" {
  description = "CloudFront geo restriction mode: none, whitelist, or blacklist."
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

variable "enable_origin_auth_header" {
  description = "Enable custom origin authentication headers"
  type        = bool
  default     = true
}

variable "origin_auth_header_name" {
  description = "Primary custom header name for origin auth"
  type        = string
  default     = "X-Origin-Verify"
}

variable "origin_auth_header_value" {
  description = "Primary custom header value for origin auth"
  type        = string
  default     = ""
  sensitive   = true
}

variable "origin_auth_previous_header_name" {
  description = "Secondary custom header name for origin auth rotation"
  type        = string
  default     = "X-Origin-Verify-Prev"
}

variable "origin_auth_previous_header_value" {
  description = "Secondary custom header value for origin auth rotation"
  type        = string
  default     = ""
  sensitive   = true
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
  description = "Prefix used for backend CloudFront log objects"
  type        = string
  default     = "cloudfront/backend/"
}

variable "enable_environment_suffix" {
  description = "Suffix aliases and tags with environment"
  type        = bool
  default     = false
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for naming and tagging. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}

variable "web_acl_id" {
  description = "Optional WAFv2 Web ACL ARN"
  type        = string
  default     = null
}
