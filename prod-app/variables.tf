variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "aws_region" {
  description = "Primary region for production app deployment root."
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "DR region for production app deployment root."
  type        = string
  default     = "us-west-2"
}

variable "prod_app_role_arn" {
  description = "Role ARN assumed for production app account deployments."
  type        = string
  default     = null
}

variable "us_east_1_role_arn" {
  description = "Optional dedicated role ARN for us-east-1 provider alias. Defaults to prod_app_role_arn."
  type        = string
  default     = null
}

variable "dr_role_arn" {
  description = "Optional dedicated role ARN for DR provider alias. Defaults to prod_app_role_arn."
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

variable "route53_zone_strategy" {
  description = "How to resolve the public Route53 hosted zone when route53_zone_id is not set."
  type        = string
  default     = "explicit"

  validation {
    condition     = contains(["explicit", "autodiscover", "create"], var.route53_zone_strategy)
    error_message = "route53_zone_strategy must be one of explicit, autodiscover, or create."
  }
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

variable "backend_ingress_mode" {
  description = "Backend ingress architecture: vpc_origin_alb for private CloudFront VPC origins or public_alb_restricted for CloudFront-restricted public ALBs."
  type        = string
  default     = "vpc_origin_alb"

  validation {
    condition     = contains(["vpc_origin_alb", "public_alb_restricted"], var.backend_ingress_mode)
    error_message = "backend_ingress_mode must be either vpc_origin_alb or public_alb_restricted."
  }
}

variable "live_validation_mode" {
  description = "Enable isolated live-validation behavior for this root."
  type        = bool
  default     = false
}

variable "live_validation_dns_label" {
  description = "Stable DNS label used by live validation for public aliases."
  type        = string
  default     = null
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

variable "allowed_image_registries" {
  description = "Optional list of approved image repository prefixes. Leave empty to enforce the managed ECR repository prefix."
  type        = list(string)
  default     = []
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
  description = "RDS master username for production database."
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class for the production database."
  type        = string
  default     = "db.t4g.small"
}

variable "rds_engine_version" {
  description = "RDS engine version for the production database."
  type        = string
  default     = "8.0.45"
}

variable "rds_enable_performance_insights" {
  description = "Enable RDS Performance Insights in production when the selected instance class supports it."
  type        = bool
  default     = false
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for the production RDS instance."
  type        = bool
  default     = true
}

variable "enable_rds_master_user_password_rotation" {
  description = "Enable automatic rotation for the production RDS master user secret."
  type        = bool
  default     = true
}

variable "rds_master_user_password_rotation_automatically_after_days" {
  description = "Rotation interval in days for the production RDS master user secret."
  type        = number
  default     = 30
}

variable "availability_zones" {
  description = "AZs for VPC subnet tiers."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "vpc_cidr" {
  description = "CIDR block for the production VPC."
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_app_subnet_cidrs" {
  description = "Public edge subnet CIDRs."
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs."
  type        = list(string)
  default     = ["10.30.21.0/24", "10.30.22.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private DB subnet CIDRs."
  type        = list(string)
  default     = ["10.30.11.0/24", "10.30.12.0/24"]
}

variable "private_app_nat_mode" {
  description = "Private app subnet internet egress mode for the production VPC."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "canary", "disabled"], var.private_app_nat_mode)
    error_message = "private_app_nat_mode must be one of required, canary, or disabled."
  }
}

variable "enable_cost_optimized_dev_tier" {
  description = "Enable the low-cost dev-tier profile in this root. Keep false for production."
  type        = bool
  default     = false
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
  description = "CloudFront-to-backend origin protocol policy for the primary backend origin. Only HTTPS is supported."
  type        = string
  default     = "https-only"

  validation {
    condition     = var.backend_origin_protocol_policy == "https-only"
    error_message = "backend_origin_protocol_policy must be https-only."
  }
}

variable "enable_security_baseline" {
  description = "Enable account-level baseline controls in the workload account."
  type        = bool
  default     = true
}

variable "enable_managed_waf" {
  description = "Enable managed WAF protection for the production root."
  type        = bool
  default     = true
}

variable "enable_aws_backup" {
  description = "Enable per-root AWS Backup resources for the production root."
  type        = bool
  default     = true
}

variable "enable_budget_alerts" {
  description = "Enable optional AWS Budgets alerts for the production root."
  type        = bool
  default     = false
}

variable "budget_alert_email_addresses" {
  description = "Email addresses subscribed to AWS Budgets alerts."
  type        = list(string)
  default     = []
}

variable "budget_alert_topic_arns" {
  description = "SNS topic ARNs subscribed to AWS Budgets alerts."
  type        = list(string)
  default     = []
}

variable "budget_alert_threshold_percentages" {
  description = "Percentage thresholds that trigger ACTUAL spend AWS Budgets notifications."
  type        = list(number)
  default     = [80, 100]
}

variable "budget_total_monthly_limit" {
  description = "Optional total monthly budget limit for the production root."
  type        = number
  default     = null
}

variable "budget_cloudfront_monthly_limit" {
  description = "Optional monthly budget limit for Amazon CloudFront."
  type        = number
  default     = null
}

variable "budget_vpc_monthly_limit" {
  description = "Optional monthly budget limit for Amazon Virtual Private Cloud charges, including NAT-related spend."
  type        = number
  default     = null
}

variable "budget_rds_monthly_limit" {
  description = "Optional monthly budget limit for Amazon Relational Database Service."
  type        = number
  default     = null
}

variable "enable_operational_alarms" {
  description = "Enable workload operational alarms for the production root."
  type        = bool
  default     = false
}

variable "operational_alarm_topic_arn" {
  description = "Optional SNS topic ARN receiving workload operational alarms."
  type        = string
  default     = null
}

variable "operational_alarm_alb_target_5xx_threshold" {
  description = "Threshold for backend ALB target 5xx count operational alarms."
  type        = number
  default     = 10
}

variable "operational_alarm_ecs_running_task_min_threshold" {
  description = "Minimum running task count threshold before the ECS operational alarm fires."
  type        = number
  default     = 1
}

variable "operational_alarm_rds_cpu_threshold" {
  description = "Average RDS CPU utilization threshold for the production operational alarm."
  type        = number
  default     = 80
}

variable "operational_alarm_cloudfront_5xx_rate_threshold" {
  description = "CloudFront 5xx error rate threshold for the production operational alarm."
  type        = number
  default     = 5
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

variable "ecs_exec_log_retention_days" {
  description = "CloudWatch log retention days for ECS Exec audit logs."
  type        = number
  default     = 365
}

variable "enable_ecs_exec_audit_alerts" {
  description = "Enable production alerts when ECS Exec is invoked."
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
  description = "AWS Organizations ID used for shared deployment metadata."
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
  description = "Production account ID."
  type        = string
  default     = null
}
