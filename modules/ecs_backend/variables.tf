variable "private_subnet_ids" {
  description = "Private subnet IDs used by ECS Fargate tasks"
  type        = list(string)
}

variable "service_security_group_id" {
  description = "Security group ID attached to ECS service tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN for ECS service registration"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name base"
  type        = string
  default     = "app-backend-cluster"
}

variable "service_name" {
  description = "ECS service name base"
  type        = string
  default     = "app-backend-service"
}

variable "task_family" {
  description = "ECS task definition family base"
  type        = string
  default     = "app-backend-task"
}

variable "execution_role_name" {
  description = "IAM execution role name base for ECS tasks"
  type        = string
  default     = "ecs-backend-execution-role"
}

variable "task_role_name" {
  description = "IAM task role name base for ECS tasks"
  type        = string
  default     = "ecs-backend-task-role"
}

variable "container_name" {
  description = "Container name used in ECS task definition"
  type        = string
  default     = "backend"
}

variable "container_image" {
  description = "Container image URI for backend service"
  type        = string
}

variable "container_port" {
  description = "Container listening port"
  type        = number
  default     = 8088
}

variable "container_user" {
  description = "Container runtime user in UID:GID form."
  type        = string
  default     = "10001:10001"
}

variable "readonly_root_fs" {
  description = "Run container with read-only root filesystem."
  type        = bool
  default     = true
}

variable "drop_capabilities" {
  description = "Linux capabilities to drop from container runtime."
  type        = list(string)
  default     = ["ALL"]
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired ECS task count"
  type        = number
  default     = 2
}

variable "min_count" {
  description = "Minimum ECS task count for autoscaling"
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Maximum ECS task count for autoscaling"
  type        = number
  default     = 4
}

variable "cpu_target_value" {
  description = "Target CPU utilization for ECS service autoscaling"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization for ECS service autoscaling"
  type        = number
  default     = 75
}

variable "alb_request_count_target_value" {
  description = "Target ALB request count per target for autoscaling. Leave null to disable Step Scaling."
  type        = number
  default     = null
}

variable "health_check_grace_period_seconds" {
  description = "ECS service health-check grace period in seconds."
  type        = number
  default     = 60
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for break-glass task access."
  type        = bool
  default     = false
}

variable "exec_kms_key_arn" {
  description = "KMS key ARN for ECS Exec session encryption."
  type        = string
  default     = null
}

variable "exec_log_group_name" {
  description = "CloudWatch log group base name for ECS Exec audit logs."
  type        = string
  default     = "app-backend-ecs-exec"
}

variable "exec_log_retention_days" {
  description = "CloudWatch log retention for ECS Exec audit logs."
  type        = number
  default     = 365
}

variable "scale_in_cooldown_seconds" {
  description = "Autoscaling scale-in cooldown in seconds"
  type        = number
  default     = 60
}

variable "scale_out_cooldown_seconds" {
  description = "Autoscaling scale-out cooldown in seconds"
  type        = number
  default     = 60
}

variable "alb_request_count_scale_in_cooldown_seconds" {
  description = "Scale-in cooldown (seconds) for ALB request count ECS autoscaling"
  type        = number
  default     = 300
}

variable "alb_request_count_scale_out_cooldown_seconds" {
  description = "Scale-out cooldown (seconds) for ALB request count ECS autoscaling"
  type        = number
  default     = 60
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics dimensions."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ALB target group ARN suffix for CloudWatch metrics dimensions."
  type        = string
}

variable "deploy_alarm_5xx_threshold" {
  description = "Threshold for ALB target 5xx deployment alarm."
  type        = number
  default     = 10
}

variable "deploy_alarm_unhealthy_hosts_threshold" {
  description = "Threshold for ALB unhealthy hosts deployment alarm."
  type        = number
  default     = 1
}

variable "deploy_alarm_eval_periods" {
  description = "Evaluation periods for ECS deployment rollback alarms."
  type        = number
  default     = 2
}

variable "environment" {
  description = "Plaintext environment variables passed to container"
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Map of container environment variable names to Secrets Manager/SSM ARNs"
  type        = map(string)
  default     = {}
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for ECS resource naming. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}

variable "secret_kms_key_arns" {
  description = "Optional list of KMS key ARNs used to decrypt referenced secrets"
  type        = list(string)
  default     = []
}

variable "log_group_name" {
  description = "CloudWatch log group name base"
  type        = string
  default     = "app-backend"
}

variable "log_retention_days" {
  description = "CloudWatch log retention for ECS backend"
  type        = number
  default     = 30
}

variable "log_kms_key_id" {
  description = "Optional KMS key ARN for ECS backend CloudWatch logs"
  type        = string
  default     = null
}

variable "task_role_policy_json" {
  description = "Optional inline IAM policy JSON document attached to the ECS task role"
  type        = string
  default     = null
}

variable "enable_environment_suffix" {
  description = "Suffix ECS resource names with environment"
  type        = bool
  default     = false
}
