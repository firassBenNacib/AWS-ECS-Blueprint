variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "aws_region" {
  description = "Primary region for non-production app deployment root."
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "DR region for non-production app deployment root."
  type        = string
  default     = "us-west-2"
}

variable "nonprod_app_role_arn" {
  description = "Role ARN assumed for non-production app account deployments."
  type        = string
  default     = null
}

variable "us_east_1_role_arn" {
  description = "Optional dedicated role ARN for us-east-1 provider alias. Defaults to nonprod_app_role_arn."
  type        = string
  default     = null
}

variable "dr_role_arn" {
  description = "Optional dedicated role ARN for DR provider alias. Defaults to nonprod_app_role_arn."
  type        = string
  default     = null
}

variable "assume_role_external_id" {
  description = "Optional external ID for role assumption."
  type        = string
  default     = null
}

variable "environment_domain" {
  description = "Base domain used for environment-specific routing."
  type        = string
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID override for public records."
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Primary frontend S3 bucket base name."
  type        = string
}

variable "app_runtime_mode" {
  description = "Application runtime mode: single_backend or gateway_microservices."
  type        = string
  default     = "single_backend"

  validation {
    condition     = contains(["single_backend", "gateway_microservices"], var.app_runtime_mode)
    error_message = "app_runtime_mode must be either single_backend or gateway_microservices."
  }
}

variable "frontend_runtime_mode" {
  description = "Frontend runtime mode: s3 (S3+CloudFront) or ecs (CloudFront to ALB/ECS)."
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "ecs"], var.frontend_runtime_mode)
    error_message = "frontend_runtime_mode must be either s3 or ecs."
  }
}

variable "backend_container_image" {
  description = "Digest-pinned backend container image URI."
  type        = string
  default     = null
}

variable "service_discovery_namespace_name" {
  description = "Optional Cloud Map private DNS namespace for gateway_microservices mode."
  type        = string
  default     = null
}

variable "ecs_services" {
  description = "Logical ECS services map passed through to gateway_microservices mode."
  type = map(object({
    image                             = string
    container_port                    = number
    container_name                    = optional(string)
    public                            = optional(bool)
    desired_count                     = optional(number)
    min_count                         = optional(number)
    max_count                         = optional(number)
    cpu                               = optional(number)
    memory                            = optional(number)
    health_check_grace_period_seconds = optional(number)
    health_check_path                 = optional(string)
    container_user                    = optional(string)
    readonly_root_fs                  = optional(bool)
    drop_capabilities                 = optional(list(string))
    env                               = optional(map(string))
    secret_arns                       = optional(map(string))
    secret_kms_key_arns               = optional(list(string))
    task_role_policy_json             = optional(string)
    log_group_name                    = optional(string)
    log_retention_days                = optional(number)
    log_kms_key_id                    = optional(string)
    entrypoint                        = optional(list(string))
    command                           = optional(list(string))
    health_check_command              = optional(list(string))
    health_check_interval_seconds     = optional(number)
    health_check_timeout_seconds      = optional(number)
    health_check_retries              = optional(number)
    health_check_start_period_seconds = optional(number)
    mount_points = optional(list(object({
      source_volume  = string
      container_path = string
      read_only      = optional(bool)
    })))
    task_volumes = optional(list(object({
      name = string
    })))
    extra_egress = optional(list(object({
      description = string
      protocol    = string
      from_port   = number
      to_port     = number
      cidr_blocks = list(string)
    })))
    assign_public_ip         = optional(bool)
    enable_service_discovery = optional(bool)
    discovery_name           = optional(string)
  }))
  default = {}
}

variable "backend_geo_restriction_type" {
  description = "Backend CloudFront geo restriction mode: none, whitelist, or blacklist."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.backend_geo_restriction_type)
    error_message = "backend_geo_restriction_type must be one of none, whitelist, or blacklist."
  }
}

variable "backend_geo_locations" {
  description = "ISO 3166-1 alpha-2 country codes used when backend_geo_restriction_type is whitelist or blacklist."
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.backend_geo_restriction_type == "none" ||
      length(var.backend_geo_locations) > 0
    )
    error_message = "backend_geo_locations must contain at least one country code when backend_geo_restriction_type is whitelist or blacklist."
  }
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

variable "acm_cert_frontend" {
  description = "ACM certificate ARN in us-east-1 for the single public CloudFront distribution."
  type        = string
}

variable "backend_cache_policy_id" {
  description = "CloudFront cache policy ID for backend distribution."
  type        = string
}

variable "backend_origin_request_policy_id" {
  description = "CloudFront origin request policy ID for backend distribution."
  type        = string
}

variable "rds_username" {
  description = "RDS master username for non-production database."
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class for the non-production database."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_enable_performance_insights" {
  description = "Enable RDS Performance Insights in non-production when the selected instance class supports it."
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "AZs for VPC subnet tiers."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "vpc_cidr" {
  description = "CIDR block for the non-production VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_app_subnet_cidrs" {
  description = "Public edge subnet CIDRs."
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs."
  type        = list(string)
  default     = ["10.40.21.0/24", "10.40.22.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private DB subnet CIDRs."
  type        = list(string)
  default     = ["10.40.11.0/24", "10.40.12.0/24"]
}

variable "private_app_nat_mode" {
  description = "Private app subnet internet egress mode for the non-production VPC."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "canary", "disabled"], var.private_app_nat_mode)
    error_message = "private_app_nat_mode must be one of required, canary, or disabled."
  }
}

variable "alb_certificate_arn" {
  description = "Regional ACM certificate ARN for internal ALB HTTPS listener."
  type        = string
}

variable "origin_auth_header_ssm_parameter_name" {
  description = "SSM parameter name for origin authentication header value."
  type        = string
}

variable "cloudfront_logs_bucket_name" {
  description = "CloudFront access logs bucket name."
  type        = string
}

variable "backend_origin_protocol_policy" {
  description = "CloudFront VPC-origin protocol policy for the primary backend origin."
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only"], var.backend_origin_protocol_policy)
    error_message = "backend_origin_protocol_policy must be one of http-only or https-only."
  }
}

variable "enable_security_baseline" {
  description = "Enable account-level baseline controls in the workload account."
  type        = bool
  default     = true
}

variable "enable_account_security_controls" {
  description = "When true, this root owns account-level security controls in the current AWS account."
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config recorder and delivery channel in the workload account baseline."
  type        = bool
  default     = true
}

variable "security_baseline_enable_object_lock" {
  description = "Enable object lock on the security baseline log bucket."
  type        = bool
  default     = false
}

variable "destroy_mode_enabled" {
  description = "Relax production deletion guards to allow clean teardown."
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection on the workload RDS instance."
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot_on_destroy" {
  description = "Skip the final RDS snapshot during destroy."
  type        = bool
  default     = false
}

variable "org_id" {
  description = "Organizations ID for cross-deployment contract metadata."
  type        = string
  default     = null
}

variable "security_account_id" {
  description = "Security tooling account ID."
  type        = string
  default     = null
}

variable "log_archive_account_id" {
  description = "Log archive account ID."
  type        = string
  default     = null
}

variable "prod_account_id" {
  description = "Production account ID (contract variable)."
  type        = string
  default     = null
}

variable "backend_failover_domain_name" {
  description = "Optional DR backend origin domain for CloudFront failover. Set to a real DR ALB/API domain when you have one; leave null to use the primary ALB (no real failover)."
  type        = string
  default     = null
}
