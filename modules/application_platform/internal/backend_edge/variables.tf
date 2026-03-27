variable "environment" {
  description = "Normalized environment naming inputs for backend edge resources."
  type = object({
    name          = string
    enable_suffix = bool
  })
}

variable "ingress" {
  description = "Resolved backend ingress and ALB wiring inputs."
  type = object({
    selected_vpc_id                     = string
    selected_alb_subnet_ids             = list(string)
    backend_ingress_is_vpc_origin       = bool
    backend_ingress_is_public           = bool
    runtime_mode_is_micro               = bool
    alb_security_group_id               = string
    microservices_alb_security_group_id = string
    alb_app_port                        = number
    alb_health_check_path               = string
    alb_listener_port                   = number
    backend_origin_protocol_policy      = string
    origin_auth_enabled                 = bool
    origin_auth_header_name             = string
    origin_auth_header_value            = string
    origin_auth_previous_header_name    = string
    origin_auth_previous_header_value   = string
  })
}

variable "alb_config" {
  description = "Resolved ALB configuration inputs."
  type = object({
    certificate_arn                  = string
    ssl_policy                       = string
    health_check_matcher             = string
    health_check_interval_seconds    = number
    health_check_timeout_seconds     = number
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    alb_name                         = string
    target_group_name                = string
    deletion_protection              = bool
    idle_timeout                     = number
    access_logs_bucket               = string
    access_logs_prefix               = string
  })
}

variable "waf_config" {
  description = "Resolved WAF configuration inputs for ALB and CloudFront."
  type = object({
    create_managed_alb        = bool
    create_managed_cloudfront = bool
    rate_limit_requests       = number
    log_retention_days        = number
    alb_web_acl_arn           = string
    frontend_web_acl_arn      = string
    backend_web_acl_arn       = string
  })
}
