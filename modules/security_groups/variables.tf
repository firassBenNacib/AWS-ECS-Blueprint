variable "vpc_id" {
  description = "The ID of the VPC where security groups are created"
  type        = string
}

variable "app_port" {
  description = "Backend application port"
  type        = number
  default     = 8080
}

variable "alb_listener_port" {
  description = "ALB listener port exposed through CloudFront VPC-origin path"
  type        = number
  default     = 443
}

variable "http_origin_listener_port" {
  description = "Optional internal HTTP listener port used by CloudFront VPC-origin traffic."
  type        = number
  default     = null
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the internal ALB listener."
  type        = list(string)

  validation {
    condition     = length(var.alb_ingress_cidr_blocks) > 0
    error_message = "alb_ingress_cidr_blocks must include at least one CIDR."
  }
}

variable "egress_endpoint_sg_id" {
  description = "Security group ID attached to Interface VPC Endpoints for private AWS API egress."
  type        = string
  default     = null
}

variable "egress_s3_prefix_list_id" {
  description = "Managed prefix list ID for Amazon S3 gateway-endpoint egress."
  type        = string
  default     = null
}

variable "enable_environment_suffix" {
  description = "Suffix security group names with environment"
  type        = bool
  default     = false
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for security-group naming. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}
