variable "environment_domain" {
  description = "Base domain used for environment-derived aliases (for example: example.com)."
  type        = string

  validation {
    condition     = trimspace(var.environment_domain) != ""
    error_message = "environment_domain must be set in this production-ready configuration."
  }
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for naming and DNS derivation. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}

variable "enable_environment_suffix" {
  description = "Append the effective environment name to shared resource names. Keep enabled for dedicated per-environment roots."
  type        = bool
  default     = true
}

variable "interface_endpoint_services" {
  description = "AWS service short names used to create Interface VPC Endpoints for private Fargate runtime dependencies."
  type        = list(string)
  default = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "sts",
    "secretsmanager",
    "kms"
  ]
}

variable "private_app_nat_mode" {
  description = "Private app subnet internet egress mode: required (all subnets via NAT), canary (single-subnet NAT route), or disabled (no NAT default route)."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "canary", "disabled"], var.private_app_nat_mode)
    error_message = "private_app_nat_mode must be one of required, canary, or disabled."
  }
}

variable "enable_security_baseline" {
  description = "Enable account-level production security baseline controls (CloudTrail, Config, GuardDuty, Security Hub, Access Analyzer)."
  type        = bool
  default     = true
}

variable "enable_account_security_controls" {
  description = "When true, this root owns account-level security controls in addition to workload infrastructure."
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config recorder and delivery channel inside the account-level security baseline."
  type        = bool
  default     = true
}

variable "securityhub_standards_arns" {
  description = "Optional explicit Security Hub standard subscription ARNs. Leave empty to use AWS Foundational + CIS defaults."
  type        = list(string)
  default     = []
}

variable "security_baseline_log_retention_days" {
  description = "Retention in days for account-level security baseline log storage lifecycle."
  type        = number
  default     = 365

  validation {
    condition     = var.security_baseline_log_retention_days >= 1 && var.security_baseline_log_retention_days == floor(var.security_baseline_log_retention_days)
    error_message = "security_baseline_log_retention_days must be an integer >= 1."
  }
}

variable "security_findings_sns_topic_arn" {
  description = "Optional existing SNS topic ARN that receives high/critical GuardDuty and Security Hub findings. When null, a managed topic is created."
  type        = string
  default     = null
}

variable "security_findings_sns_subscriptions" {
  description = "Optional managed-topic subscriptions for security findings notifications."
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default = []
}

variable "enable_cloudtrail_data_events" {
  description = "Enable CloudTrail data event selectors for high-value resource telemetry."
  type        = bool
  default     = false
}

variable "cloudtrail_data_event_resources" {
  description = "CloudTrail data-event resource ARNs (for example S3 object data selectors like arn:aws:s3:::bucket-name/)."
  type        = list(string)
  default     = []
}

variable "enable_inspector" {
  description = "Enable Amazon Inspector for account-level vulnerability scanning."
  type        = bool
  default     = true
}

variable "enable_aws_backup" {
  description = "Enable AWS Backup plan/selection for the primary RDS instance."
  type        = bool
  default     = true
}

variable "security_baseline_enable_object_lock" {
  description = "Enable S3 Object Lock on the security baseline audit-log bucket."
  type        = bool
  default     = false
}

variable "aws_backup_vault_name" {
  description = "Optional AWS Backup vault base name. When null, an environment-prefixed default is used."
  type        = string
  default     = null
}



variable "aws_backup_schedule_expression" {
  description = "Cron expression for the AWS Backup RDS backup rule."
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "aws_backup_retention_days" {
  description = "Retention period in days for primary-region recovery points."
  type        = number
  default     = 35

  validation {
    condition     = var.aws_backup_retention_days >= 1 && var.aws_backup_retention_days == floor(var.aws_backup_retention_days)
    error_message = "aws_backup_retention_days must be an integer >= 1."
  }
}

variable "aws_backup_start_window_minutes" {
  description = "Start window in minutes for the AWS Backup rule."
  type        = number
  default     = 60

  validation {
    condition     = var.aws_backup_start_window_minutes >= 60 && var.aws_backup_start_window_minutes == floor(var.aws_backup_start_window_minutes)
    error_message = "aws_backup_start_window_minutes must be an integer >= 60."
  }
}

variable "aws_backup_completion_window_minutes" {
  description = "Completion window in minutes for the AWS Backup rule."
  type        = number
  default     = 180

  validation {
    condition     = var.aws_backup_completion_window_minutes >= 60 && var.aws_backup_completion_window_minutes == floor(var.aws_backup_completion_window_minutes)
    error_message = "aws_backup_completion_window_minutes must be an integer >= 60."
  }
}

variable "aws_backup_cross_region_copy_enabled" {
  description = "When true, copy AWS Backup recovery points to a DR-region backup vault."
  type        = bool
  default     = true
}

variable "aws_backup_copy_retention_days" {
  description = "Retention period in days for copied DR-region recovery points."
  type        = number
  default     = 35

  validation {
    condition     = var.aws_backup_copy_retention_days >= 1 && var.aws_backup_copy_retention_days == floor(var.aws_backup_copy_retention_days)
    error_message = "aws_backup_copy_retention_days must be an integer >= 1."
  }
}

variable "vpc_flow_logs_retention_days" {
  description = "CloudWatch log retention days for VPC Flow Logs"
  type        = number
  default     = 365

  validation {
    condition     = var.vpc_flow_logs_retention_days >= 1
    error_message = "vpc_flow_logs_retention_days must be >= 1."
  }
}

variable "vpc_flow_logs_kms_key_id" {
  description = "Optional KMS key ARN for VPC Flow Logs encryption. When null, flow logs are not KMS-encrypted."
  type        = string
  default     = null
}

variable "lockdown_default_security_group" {
  description = "When true, remove all ingress/egress rules from the default security group of the dedicated VPC"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region for primary resources"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "AWS region for disaster-recovery replicas (S3 replication targets)"
  type        = string
  default     = "us-west-2"
}

variable "aws_assume_role_arn" {
  description = "Optional role ARN assumed by the primary AWS provider. Leave null to use ambient credentials."
  type        = string
  default     = null
}

variable "us_east_1_assume_role_arn" {
  description = "Optional role ARN assumed by aws.us_east_1 provider alias. Defaults to aws_assume_role_arn when unset."
  type        = string
  default     = null
}

variable "dr_assume_role_arn" {
  description = "Optional role ARN assumed by aws.dr provider alias. Defaults to aws_assume_role_arn when unset."
  type        = string
  default     = null
}

variable "aws_assume_role_external_id" {
  description = "Optional external ID used when assuming provider roles."
  type        = string
  default     = null
}

variable "aws_assume_role_session_name" {
  description = "Session name used for provider assume-role operations."
  type        = string
  default     = "terraform"
}

variable "project_name" {
  description = "Required project name applied to resource names, tags, and internal DNS defaults."
  type        = string
}

variable "additional_tags" {
  description = "Additional tags applied to resources through provider default tags"
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "app-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "public_app_subnet_cidrs" {
  description = "CIDR blocks for public edge subnets (ALB/NAT gateways)"
  type        = list(string)
  default     = []
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (backend service tasks)"
  type        = list(string)
  default     = []
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  default     = []
}

variable "bucket_name" {
  description = "Name of the frontend S3 bucket"
  type        = string
}

variable "s3_force_destroy" {
  description = "Allow destroying non-empty frontend S3 bucket (not recommended for production)"
  type        = bool
  default     = false
}

variable "destroy_mode_enabled" {
  description = "Relax deletion protections and enable force-destroy semantics for repeatable teardown."
  type        = bool
  default     = false
}

variable "s3_versioning_enabled" {
  description = "Enable frontend bucket versioning"
  type        = bool
  default     = true
}

variable "s3_kms_key_id" {
  description = "Optional KMS key ARN for primary-region S3 encryption. When null, a managed key is created."
  type        = string
  default     = null
}

variable "dr_s3_kms_key_id" {
  description = "Optional KMS key ARN for DR-region S3 replica encryption. When null, a managed key is created in the DR region."
  type        = string
  default     = null
}


variable "enable_s3_lifecycle" {
  description = "Enable lifecycle rules on the frontend S3 bucket"
  type        = bool
  default     = false
}

variable "s3_lifecycle_expiration_days" {
  description = "Optional expiration age (days) for current frontend S3 objects"
  type        = number
  default     = null
}

variable "s3_lifecycle_noncurrent_expiration_days" {
  description = "Optional expiration age (days) for noncurrent frontend S3 object versions"
  type        = number
  default     = 30
}

variable "s3_lifecycle_abort_incomplete_multipart_upload_days" {
  description = "Abort incomplete multipart uploads in frontend S3 bucket after this many days"
  type        = number
  default     = 7

  validation {
    condition     = var.s3_lifecycle_abort_incomplete_multipart_upload_days >= 1 && var.s3_lifecycle_abort_incomplete_multipart_upload_days == floor(var.s3_lifecycle_abort_incomplete_multipart_upload_days)
    error_message = "s3_lifecycle_abort_incomplete_multipart_upload_days must be an integer >= 1."
  }
}

variable "app_runtime_mode" {
  description = "Application runtime topology. single_backend keeps the existing one-service backend path; gateway_microservices exposes one public ECS service behind the ALB and keeps the remaining ECS services private behind service discovery."
  type        = string
  default     = "single_backend"

  validation {
    condition     = contains(["single_backend", "gateway_microservices"], var.app_runtime_mode)
    error_message = "app_runtime_mode must be one of single_backend or gateway_microservices."
  }
}

variable "frontend_runtime_mode" {
  description = "Frontend runtime topology. s3 keeps the current S3+CloudFront static model; ecs targets the internal ALB/ECS frontend origin."
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "ecs"], var.frontend_runtime_mode)
    error_message = "frontend_runtime_mode must be one of s3 or ecs."
  }
}

variable "service_discovery_namespace_name" {
  description = "Optional private DNS namespace used for ECS service discovery in gateway_microservices mode. Leave null to derive an environment-specific internal namespace."
  type        = string
  default     = null
}

variable "ecs_services" {
  description = "Generic ECS service map used in gateway_microservices mode."
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
    mount_points = optional(list(object({
      source_volume  = string
      container_path = string
      read_only      = optional(bool)
    })))
    task_volumes = optional(list(object({
      name = string
    })))
    health_check_command              = optional(list(string))
    health_check_interval_seconds     = optional(number)
    health_check_timeout_seconds      = optional(number)
    health_check_retries              = optional(number)
    health_check_start_period_seconds = optional(number)
    assign_public_ip                  = optional(bool)
    enable_service_discovery          = optional(bool)
    discovery_name                    = optional(string)
    extra_egress = optional(list(object({
      description = string
      protocol    = string
      from_port   = number
      to_port     = number
      cidr_blocks = list(string)
    })))
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

variable "backend_container_image" {
  description = "Container image URI for backend ECS service. Production requires digest-pinned form (for example: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/app@sha256:<digest>)."
  type        = string
  default     = null

  validation {
    condition = (
      var.app_runtime_mode != "single_backend" ||
      (var.backend_container_image != null && can(regex("^.+@sha256:[A-Fa-f0-9]{64}$", trimspace(var.backend_container_image))))
    )
    error_message = "backend_container_image must be digest-pinned in the form <image>@sha256:<64-hex> when app_runtime_mode=single_backend."
  }
}

variable "allowed_image_registries" {
  description = "Optional list of approved container image URI prefixes (for example: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/repo). When empty, the managed backend ECR repository prefix is enforced."
  type        = list(string)
  default     = []
}

variable "create_backend_ecr_repository" {
  description = "Create a managed ECR repository for backend images with immutable tags and scan-on-push."
  type        = bool
  default     = true
}

variable "backend_ecr_repository_name" {
  description = "Backend ECR repository base name."
  type        = string
  default     = "app-backend"
}

variable "backend_ecr_lifecycle_max_images" {
  description = "Maximum number of backend container images to retain in ECR."
  type        = number
  default     = 30

  validation {
    condition     = var.backend_ecr_lifecycle_max_images >= 1 && var.backend_ecr_lifecycle_max_images == floor(var.backend_ecr_lifecycle_max_images)
    error_message = "backend_ecr_lifecycle_max_images must be an integer >= 1."
  }
}

variable "backend_ecr_kms_key_arn" {
  description = "Optional KMS key ARN for ECR repository encryption. When null, ECR uses the default AWS-managed key."
  type        = string
  default     = null
}

variable "backend_container_port" {
  description = "Backend container listening port"
  type        = number
  default     = 8088
}

variable "backend_healthcheck_path" {
  description = "ALB health check path for backend service"
  type        = string
  default     = "/health"
}

variable "backend_cluster_name" {
  description = "ECS cluster name base"
  type        = string
  default     = "app-backend-cluster"
}

variable "backend_service_name" {
  description = "ECS service name base"
  type        = string
  default     = "app-backend-service"
}

variable "backend_task_family" {
  description = "ECS task definition family base"
  type        = string
  default     = "app-backend-task"
}

variable "backend_execution_role_name" {
  description = "ECS task execution IAM role name base"
  type        = string
  default     = "ecs-backend-execution-role"
}

variable "backend_task_role_name" {
  description = "ECS task IAM role name base"
  type        = string
  default     = "ecs-backend-task-role"
}

variable "backend_container_name" {
  description = "Container name used by ECS task definition and service load balancer mapping"
  type        = string
  default     = "backend"
}

variable "backend_container_user" {
  description = "Container runtime user in UID:GID form."
  type        = string
  default     = "10001:10001"

  validation {
    condition     = can(regex("^[0-9]+:[0-9]+$", trimspace(var.backend_container_user)))
    error_message = "backend_container_user must be in UID:GID format (for example 10001:10001)."
  }
}

variable "backend_readonly_root_filesystem" {
  description = "Run backend container with a read-only root filesystem."
  type        = bool
  default     = true
}

variable "backend_drop_linux_capabilities" {
  description = "Linux capabilities to drop in backend container runtime."
  type        = list(string)
  default     = ["ALL"]

  validation {
    condition     = length(var.backend_drop_linux_capabilities) > 0
    error_message = "backend_drop_linux_capabilities must contain at least one capability."
  }
}

variable "backend_healthcheck_grace_period_seconds" {
  description = "ECS service health-check grace period in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.backend_healthcheck_grace_period_seconds >= 0 && var.backend_healthcheck_grace_period_seconds == floor(var.backend_healthcheck_grace_period_seconds)
    error_message = "backend_healthcheck_grace_period_seconds must be an integer >= 0."
  }
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for break-glass debugging access."
  type        = bool
  default     = false
}



variable "ecs_exec_log_group_name" {
  description = "CloudWatch log group base name for ECS Exec audit logs."
  type        = string
  default     = "app-backend-ecs-exec"
}

variable "ecs_exec_log_retention_days" {
  description = "CloudWatch log retention days for ECS Exec audit logs."
  type        = number
  default     = 30

  validation {
    condition     = var.ecs_exec_log_retention_days >= 1 && var.ecs_exec_log_retention_days == floor(var.ecs_exec_log_retention_days)
    error_message = "ecs_exec_log_retention_days must be an integer >= 1."
  }
}

variable "backend_task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "backend_task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Desired ECS task count"
  type        = number
  default     = 2
}

variable "backend_min_count" {
  description = "Minimum ECS task count for autoscaling"
  type        = number
  default     = 2
}

variable "backend_max_count" {
  description = "Maximum ECS task count for autoscaling"
  type        = number
  default     = 4
}

variable "backend_cpu_target_value" {
  description = "Target ECS service CPU utilization percentage for autoscaling"
  type        = number
  default     = 70
}

variable "backend_memory_target_value" {
  description = "Target ECS service memory utilization percentage for autoscaling"
  type        = number
  default     = 75
}

variable "backend_alb_request_count_target_value" {
  description = "Target ALB request count per target for autoscaling. Leave null to disable Step Scaling."
  type        = number
  default     = null
}

variable "backend_deploy_alarm_5xx_threshold" {
  description = "Alarm threshold for ALB target 5xx errors during ECS deployments."
  type        = number
  default     = 10
}

variable "backend_deploy_alarm_unhealthy_hosts_threshold" {
  description = "Alarm threshold for unhealthy ALB targets during ECS deployments."
  type        = number
  default     = 1
}

variable "backend_deploy_alarm_eval_periods" {
  description = "Number of evaluation periods for ECS deployment rollback alarms."
  type        = number
  default     = 2

  validation {
    condition     = var.backend_deploy_alarm_eval_periods >= 1 && var.backend_deploy_alarm_eval_periods == floor(var.backend_deploy_alarm_eval_periods)
    error_message = "backend_deploy_alarm_eval_periods must be an integer >= 1."
  }
}

variable "backend_scale_in_cooldown_seconds" {
  description = "Scale-in cooldown (seconds) for ECS autoscaling"
  type        = number
  default     = 60
}

variable "backend_scale_out_cooldown_seconds" {
  description = "Scale-out cooldown (seconds) for ECS autoscaling"
  type        = number
  default     = 60
}

variable "backend_alb_request_count_scale_in_cooldown_seconds" {
  description = "Scale-in cooldown (seconds) for ALB request count ECS autoscaling"
  type        = number
  default     = 300
}

variable "backend_alb_request_count_scale_out_cooldown_seconds" {
  description = "Scale-out cooldown (seconds) for ALB request count ECS autoscaling"
  type        = number
  default     = 60
}

variable "backend_env" {
  description = "Additional plaintext environment variables for backend container"
  type        = map(string)
  default     = {}
}

variable "backend_secret_arns" {
  description = "Map of environment variable names to Secrets Manager/SSM secret ARNs for backend container"
  type        = map(string)
  default     = {}
}

variable "backend_secret_kms_key_arns" {
  description = "Optional list of KMS key ARNs required to decrypt backend secrets"
  type        = list(string)
  default     = []
}

variable "backend_task_role_policy_json" {
  description = "Optional inline IAM policy JSON attached to backend ECS task role"
  type        = string
  default     = null
}

variable "backend_log_group_name" {
  description = "CloudWatch log group name base for backend ECS logs"
  type        = string
  default     = "app-backend"
}

variable "backend_log_retention_days" {
  description = "CloudWatch log retention days for backend ECS logs"
  type        = number
  default     = 30
}

variable "backend_log_kms_key_id" {
  description = "Optional KMS key ARN for backend ECS CloudWatch log group encryption."
  type        = string
  default     = null
}

variable "backend_rds_secret_env_var_name" {
  description = "Environment variable name used to inject the RDS managed secret into backend ECS tasks"
  type        = string
  default     = "DB_CREDENTIALS"

  validation {
    condition     = trimspace(var.backend_rds_secret_env_var_name) != ""
    error_message = "backend_rds_secret_env_var_name must not be empty."
  }
}

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

variable "backend_failover_domain_name" {
  description = "Optional secondary backend origin domain for CloudFront origin failover (e.g. DR ALB/API). When null or empty, the primary ALB is used as failover so the distribution remains valid without a real DR endpoint."
  type        = string
  default     = null
}

variable "backend_failover_origin_protocol_policy" {
  description = "CloudFront protocol policy for the secondary backend origin"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only"], var.backend_failover_origin_protocol_policy)
    error_message = "backend_failover_origin_protocol_policy must be one of http-only or https-only."
  }
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

variable "backend_response_headers_policy_id" {
  description = "CloudFront response headers policy ID for backend distribution"
  type        = string
  default     = "67f7725c-6f97-4210-82d7-5512b31e9d03"
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

variable "backend_price_class" {
  description = "CloudFront price class for backend distribution"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.backend_price_class)
    error_message = "backend_price_class must be one of PriceClass_All, PriceClass_200, or PriceClass_100."
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

variable "frontend_response_headers_policy_id" {
  description = "CloudFront response headers policy ID for frontend distribution"
  type        = string
  default     = "67f7725c-6f97-4210-82d7-5512b31e9d03"
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

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "app-rds"
}

variable "rds_db_name" {
  description = "Database name"
  type        = string
  default     = "app"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_enable_performance_insights" {
  description = "Enable RDS Performance Insights when the selected instance class supports it."
  type        = bool
  default     = false
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB for autoscaling. Set to 0 to disable. Defaults to 100 GB to allow online autoscaling."
  type        = number
  default     = 100

  validation {
    condition     = var.rds_max_allocated_storage == 0 || var.rds_max_allocated_storage >= 20
    error_message = "rds_max_allocated_storage must be 0 (disabled) or >= 20 GB."
  }
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 14
}

variable "rds_preferred_backup_window" {
  description = "Preferred daily backup window for RDS (UTC)."
  type        = string
  default     = "03:00-04:00"
}

variable "rds_preferred_maintenance_window" {
  description = "Preferred weekly maintenance window for RDS (UTC)."
  type        = string
  default     = "sun:04:30-sun:05:30"
}



variable "rds_final_snapshot_identifier" {
  description = "Optional final snapshot identifier"
  type        = string
  default     = null
}

variable "rds_deletion_protection" {
  description = "Enable RDS deletion protection during normal operation."
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot_on_destroy" {
  description = "Skip the final RDS snapshot on destroy. destroy_mode_enabled forces this on."
  type        = bool
  default     = false
}

variable "enable_rds_iam_auth" {
  description = "Enable IAM database authentication for RDS MySQL"
  type        = bool
  default     = true
}

variable "rds_monitoring_interval_seconds" {
  description = "Enhanced monitoring interval for RDS in seconds (0 disables)"
  type        = number
  default     = 60
}

variable "rds_enabled_cloudwatch_logs_exports" {
  description = "RDS MySQL log types exported to CloudWatch Logs"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
}

variable "rds_master_user_secret_kms_key_id" {
  description = "Optional KMS key ID or ARN for RDS managed master user secret encryption. When null, Secrets Manager uses the default key."
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Optional Route 53 public hosted zone ID override. When null, Terraform reuses the longest matching public zone suffix or creates a zone for environment_domain if none exists."
  type        = string
  default     = null
}
