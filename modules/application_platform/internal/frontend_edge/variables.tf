variable "environment" {
  description = "Normalized environment naming inputs for frontend edge resources."
  type = object({
    name          = string
    enable_suffix = bool
    domain        = string
    project_name  = string
  })
}

variable "frontend" {
  description = "Resolved frontend distribution inputs."
  type = object({
    bucket_domain           = string
    secondary_bucket_domain = string
    aliases                 = list(string)
    cert_arn                = string
    cache_policy_id         = string
    price_class             = string
    viewer_protocol_policy  = string
    geo_restriction_type    = string
    geo_locations           = list(string)
    access_logs_bucket      = string
    access_logs_prefix      = string
    runtime_mode            = string
    alb_domain_name         = string
    vpc_origin_id           = string
    alb_https_port          = number
  })
}

variable "backend" {
  description = "Resolved backend path-routing inputs embedded in the frontend distribution."
  type = object({
    origin_enabled                    = bool
    origin_domain_name                = string
    origin_vpc_origin_id              = string
    origin_https_port                 = number
    origin_protocol_policy            = string
    viewer_protocol_policy            = string
    cache_policy_id                   = string
    origin_request_policy_id          = string
    allowed_methods                   = list(string)
    path_patterns                     = list(string)
    origin_auth_enabled               = bool
    origin_auth_header_name           = string
    origin_auth_header_value          = string
    origin_auth_previous_header_name  = string
    origin_auth_previous_header_value = string
  })
}

variable "route53_zone_id_effective" {
  description = "Hosted zone ID used for frontend public aliases."
  type        = string
}

variable "web_acl_id" {
  description = "Optional CloudFront Web ACL ARN."
  type        = string
  default     = null
}
