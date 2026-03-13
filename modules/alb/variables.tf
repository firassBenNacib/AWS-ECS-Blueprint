variable "vpc_id" {
  description = "VPC ID where ALB and target group are created"
  type        = string
}

variable "alb_subnet_ids" {
  description = "Subnet IDs used by ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID attached to ALB"
  type        = string
}

variable "app_port" {
  description = "Backend application port used by target group"
  type        = number
  default     = 8080
}

variable "alb_listener_port" {
  description = "Primary ALB HTTPS listener port"
  type        = number
  default     = 443
}

variable "enable_origin_http_listener" {
  description = "Create an internal HTTP listener dedicated to CloudFront VPC-origin traffic."
  type        = bool
  default     = false
}

variable "origin_http_listener_port" {
  description = "Port used by the optional internal HTTP listener for CloudFront VPC-origin traffic."
  type        = number
  default     = 80
}

variable "certificate_arn" {
  description = "Regional ACM certificate ARN for ALB HTTPS listener"
  type        = string
}

variable "ssl_policy" {
  description = "SSL policy for ALB HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/health"
}

variable "health_check_matcher" {
  description = "ALB target group health check matcher"
  type        = string
  default     = "200-399"
}

variable "health_check_interval_seconds" {
  description = "ALB target group health check interval"
  type        = number
  default     = 30
}

variable "health_check_timeout_seconds" {
  description = "ALB target group health check timeout"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "ALB target group healthy threshold count"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "ALB target group unhealthy threshold count"
  type        = number
  default     = 3
}

variable "target_type" {
  description = "Target type for ALB target group. ECS Fargate requires ip."
  type        = string
  default     = "ip"

  validation {
    condition     = contains(["instance", "ip", "lambda", "alb"], var.target_type)
    error_message = "target_type must be one of instance, ip, lambda, or alb."
  }
}

variable "enable_environment_suffix" {
  description = "Suffix ALB resources with environment"
  type        = bool
  default     = false
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for ALB resource naming. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}

variable "alb_name" {
  description = "ALB name base"
  type        = string
  default     = "app-backend-alb"
}

variable "target_group_name" {
  description = "Target group name base"
  type        = string
  default     = "app-backend-tg"
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000 && var.idle_timeout == floor(var.idle_timeout)
    error_message = "idle_timeout must be an integer between 1 and 4000."
  }
}

variable "access_logs_bucket" {
  description = "S3 bucket name where ALB access logs are stored"
  type        = string
}

variable "access_logs_prefix" {
  description = "Prefix for ALB access log objects"
  type        = string
  default     = "alb/"
}

variable "enable_origin_auth_header" {
  description = "Enable CloudFront origin custom-header enforcement at ALB listener level"
  type        = bool
  default     = true
}

variable "origin_auth_header_name" {
  description = "Primary origin auth header name accepted by ALB listener rules"
  type        = string
  default     = "X-Origin-Verify"
}

variable "origin_auth_header_value" {
  description = "Primary origin auth header value accepted by ALB listener rules"
  type        = string
  default     = ""
  sensitive   = true
}

variable "origin_auth_previous_header_name" {
  description = "Secondary origin auth header name accepted during header rotation"
  type        = string
  default     = "X-Origin-Verify-Prev"
}

variable "origin_auth_previous_header_value" {
  description = "Secondary origin auth header value accepted during header rotation"
  type        = string
  default     = ""
  sensitive   = true
}
