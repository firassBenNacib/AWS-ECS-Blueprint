variable "app_runtime_mode" {
  description = "Application runtime topology. single_backend keeps the existing one-service backend path; gateway_microservices exposes one public ECS service behind the ALB and keeps the remaining ECS services private behind service discovery."
  type        = string
  default     = "single_backend"

  validation {
    condition     = contains(["single_backend", "gateway_microservices"], var.app_runtime_mode)
    error_message = "app_runtime_mode must be one of single_backend or gateway_microservices."
  }
}

variable "backend_ingress_mode" {
  description = "Backend ingress architecture. vpc_origin_alb keeps the ALB private behind a CloudFront VPC origin. public_alb_restricted uses a public ALB restricted to CloudFront origin-facing infrastructure."
  type        = string
  default     = "vpc_origin_alb"

  validation {
    condition     = contains(["vpc_origin_alb", "public_alb_restricted"], var.backend_ingress_mode)
    error_message = "backend_ingress_mode must be one of vpc_origin_alb or public_alb_restricted."
  }
}

variable "live_validation_mode" {
  description = "When true, the deployment is being created only for isolated live-validation runs and must use an lv-* environment name."
  type        = bool
  default     = false
}

variable "live_validation_dns_label" {
  description = "Stable DNS label used for live-validation public aliases (for example: lv-prod). Required when live_validation_mode=true."
  type        = string
  default     = null
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
    cpu_architecture                  = optional(string)
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

variable "enable_ecs_exec_audit_alerts" {
  description = "When true, route ECS Exec shell access events to the security notifications topic in production."
  type        = bool
  default     = true
}

variable "enable_operational_alarms" {
  description = "When true, create workload-level CloudWatch alarms for ALB 5xxs, public ECS service health, RDS CPU, and CloudFront 5xx rate."
  type        = bool
  default     = false
}

variable "operational_alarm_topic_arn" {
  description = "Optional SNS topic ARN receiving workload operational alarms. When null, the module reuses the security findings topic if one exists."
  type        = string
  default     = null
}

variable "operational_alarm_alb_target_5xx_threshold" {
  description = "Threshold for backend ALB target 5xx count operational alarms."
  type        = number
  default     = 10
}

variable "operational_alarm_ecs_running_task_min_threshold" {
  description = "Minimum running task count threshold before the public ECS service operational alarm fires."
  type        = number
  default     = 1
}

variable "operational_alarm_rds_cpu_threshold" {
  description = "Average RDS CPU utilization threshold for the workload operational alarm."
  type        = number
  default     = 80
}

variable "operational_alarm_cloudfront_5xx_rate_threshold" {
  description = "CloudFront 5xx error rate threshold for the frontend operational alarm."
  type        = number
  default     = 5
}

variable "ecs_exec_log_group_name" {
  description = "CloudWatch log group base name for ECS Exec audit logs."
  type        = string
  default     = "app-backend-ecs-exec"
}

variable "ecs_exec_log_retention_days" {
  description = "CloudWatch log retention days for ECS Exec audit logs."
  type        = number
  default     = 365

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

variable "backend_task_cpu_architecture" {
  description = "Fargate CPU architecture for the backend task definition."
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.backend_task_cpu_architecture)
    error_message = "backend_task_cpu_architecture must be ARM64 or X86_64."
  }
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
