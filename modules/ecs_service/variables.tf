variable "cluster_arn" {
  description = "ECS cluster ARN hosting the service."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name hosting the service."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by ECS Fargate tasks."
  type        = list(string)
}

variable "service_security_group_ids" {
  description = "Security group IDs attached to ECS tasks."
  type        = list(string)
}

variable "service_name" {
  description = "ECS service name."
  type        = string
}

variable "task_family" {
  description = "ECS task definition family."
  type        = string
}

variable "execution_role_name" {
  description = "IAM execution role name for ECS tasks."
  type        = string
}

variable "task_role_name" {
  description = "IAM task role name for ECS tasks."
  type        = string
}

variable "container_name" {
  description = "Primary container name used in the ECS task definition."
  type        = string
}

variable "container_image" {
  description = "Digest-pinned container image URI."
  type        = string

  validation {
    condition     = can(regex("^.+@sha256:[A-Fa-f0-9]{64}$", trimspace(var.container_image)))
    error_message = "container_image must be digest-pinned in the form <image>@sha256:<64-hex>."
  }
}

variable "container_port" {
  description = "Primary container listening port."
  type        = number
}

variable "container_user" {
  description = "Optional container runtime user in UID:GID form. Leave null to use the image default user."
  type        = string
  default     = null
}

variable "readonly_root_fs" {
  description = "Run the container with a read-only root filesystem."
  type        = bool
  default     = true
}

variable "drop_capabilities" {
  description = "Linux capabilities to drop from the container runtime."
  type        = list(string)
  default     = ["ALL"]
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "task_cpu_architecture" {
  description = "Fargate task CPU architecture."
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.task_cpu_architecture)
    error_message = "task_cpu_architecture must be ARM64 or X86_64."
  }
}

variable "desired_count" {
  description = "Desired ECS task count."
  type        = number
  default     = 1
}

variable "min_count" {
  description = "Minimum ECS task count for autoscaling."
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum ECS task count for autoscaling."
  type        = number
  default     = 2
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for autoscaling."
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for autoscaling."
  type        = number
  default     = 75
}

variable "alb_request_count_target_value" {
  description = "Target ALB request count per target for autoscaling. Leave null to disable."
  type        = number
  default     = null
}

variable "health_check_grace_period_seconds" {
  description = "ECS service health-check grace period in seconds."
  type        = number
  default     = 60
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for this service."
  type        = bool
  default     = false
}

variable "exec_kms_key_arn" {
  description = "KMS key ARN used to encrypt ECS Exec sessions."
  type        = string
  default     = null
}

variable "exec_log_group_name" {
  description = "CloudWatch log group name used for ECS Exec audit logs."
  type        = string
  default     = null
}

variable "exec_log_retention_days" {
  description = "CloudWatch log retention in days for ECS Exec logs."
  type        = number
  default     = 365
}

variable "scale_in_cooldown_seconds" {
  description = "Autoscaling scale-in cooldown in seconds."
  type        = number
  default     = 60
}

variable "scale_out_cooldown_seconds" {
  description = "Autoscaling scale-out cooldown in seconds."
  type        = number
  default     = 60
}

variable "alb_request_count_scale_in_cooldown_seconds" {
  description = "Autoscaling scale-in cooldown in seconds for ALB request count policy."
  type        = number
  default     = 300
}

variable "alb_request_count_scale_out_cooldown_seconds" {
  description = "Autoscaling scale-out cooldown in seconds for ALB request count policy."
  type        = number
  default     = 60
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix used for deployment alarms. Leave null when the service is not behind the ALB."
  type        = string
  default     = null
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix used for deployment alarms. Leave null when the service is not behind the ALB."
  type        = string
  default     = null
}

variable "enable_deploy_alarms" {
  description = "Whether to create ALB-backed ECS deployment rollback alarms for this service."
  type        = bool
  default     = false

  validation {
    condition = !var.enable_deploy_alarms || (
      var.enable_load_balancer &&
      var.alb_arn_suffix != null &&
      trimspace(var.alb_arn_suffix) != "" &&
      var.target_group_arn_suffix != null &&
      trimspace(var.target_group_arn_suffix) != ""
    )
    error_message = "enable_deploy_alarms requires enable_load_balancer plus non-empty alb_arn_suffix and target_group_arn_suffix."
  }
}

variable "deploy_alarm_5xx_threshold" {
  description = "Threshold for ALB target 5xx deployment alarm."
  type        = number
  default     = 10
}

variable "deploy_alarm_unhealthy_hosts_threshold" {
  description = "Threshold for unhealthy ALB targets deployment alarm."
  type        = number
  default     = 1
}

variable "deploy_alarm_eval_periods" {
  description = "Evaluation periods for ECS deployment rollback alarms."
  type        = number
  default     = 2
}

variable "environment" {
  description = "Plaintext environment variables passed to the container."
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Map of container environment variable names to Secrets Manager/SSM ARNs."
  type        = map(string)
  default     = {}
}

variable "secret_kms_key_arns" {
  description = "Optional KMS key ARNs required to decrypt referenced secrets."
  type        = list(string)
  default     = []
}

variable "log_group_name" {
  description = "CloudWatch log group name."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention days for service logs."
  type        = number
  default     = 30
}

variable "log_kms_key_id" {
  description = "Optional KMS key ARN for the service log group."
  type        = string
  default     = null
}

variable "task_role_policy_json" {
  description = "Optional inline IAM policy JSON attached to the ECS task role."
  type        = string
  default     = null
}

variable "load_balancer_target_group_arn" {
  description = "Optional ALB target group ARN used for public service registration."
  type        = string
  default     = null
}

variable "enable_load_balancer" {
  description = "Whether to attach this ECS service to an ALB target group."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_load_balancer || (var.load_balancer_target_group_arn != null && trimspace(var.load_balancer_target_group_arn) != "")
    error_message = "enable_load_balancer requires load_balancer_target_group_arn to be set."
  }
}

variable "service_discovery_registry_arn" {
  description = "Optional Cloud Map service ARN used for service discovery registration."
  type        = string
  default     = null
}

variable "entrypoint" {
  description = "Optional container entrypoint override."
  type        = list(string)
  default     = []
}

variable "command" {
  description = "Optional container command override."
  type        = list(string)
  default     = []
}

variable "mount_points" {
  description = "Optional container mount points backed by task volumes."
  type = list(object({
    source_volume  = string
    container_path = string
    read_only      = optional(bool)
  }))
  default = []
}

variable "task_volumes" {
  description = "Optional task-scoped ephemeral volumes."
  type = list(object({
    name = string
  }))
  default = []
}

variable "health_check_command" {
  description = "Optional container health check command in ECS format, for example [\"CMD-SHELL\", \"wget ... || exit 1\"]."
  type        = list(string)
  default     = []
}

variable "health_check_interval_seconds" {
  description = "Container health check interval in seconds."
  type        = number
  default     = 30
}

variable "health_check_timeout_seconds" {
  description = "Container health check timeout in seconds."
  type        = number
  default     = 5
}

variable "health_check_retries" {
  description = "Container health check retry count."
  type        = number
  default     = 3
}

variable "health_check_start_period_seconds" {
  description = "Container health check start period in seconds."
  type        = number
  default     = 15
}

variable "assign_public_ip" {
  description = "Assign a public IP to ECS tasks."
  type        = bool
  default     = false
}
