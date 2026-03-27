variable "enabled" {
  description = "Whether workload-level operational alarms should be created."
  type        = bool
}

variable "name_prefix" {
  description = "Prefix used when naming CloudWatch alarms."
  type        = string
}

variable "notifications_topic_arn" {
  description = "Optional SNS topic ARN subscribed to CloudWatch alarm state changes."
  type        = string
  default     = null
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix used by ApplicationELB metrics."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix used by ApplicationELB metrics."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name used by RunningTaskCount metrics."
  type        = string
}

variable "ecs_service_name" {
  description = "Public ECS service name used by RunningTaskCount metrics."
  type        = string
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier used by DB metrics."
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID used by distribution metrics."
  type        = string
}

variable "alb_target_5xx_threshold" {
  description = "Threshold for backend ALB target 5xx count alarms."
  type        = number
  default     = 10
}

variable "alb_target_5xx_evaluation_periods" {
  description = "Evaluation periods for backend ALB target 5xx count alarms."
  type        = number
  default     = 2
}

variable "ecs_running_task_min_threshold" {
  description = "Minimum running task count threshold before the ECS service alarm fires."
  type        = number
  default     = 1
}

variable "ecs_running_task_evaluation_periods" {
  description = "Evaluation periods for the ECS running task count alarm."
  type        = number
  default     = 2
}

variable "rds_cpu_threshold" {
  description = "Average RDS CPU utilization threshold for the high CPU alarm."
  type        = number
  default     = 80
}

variable "rds_cpu_evaluation_periods" {
  description = "Evaluation periods for the RDS CPU alarm."
  type        = number
  default     = 3
}

variable "cloudfront_5xx_rate_threshold" {
  description = "CloudFront 5xx error rate threshold for the frontend distribution alarm."
  type        = number
  default     = 5
}

variable "cloudfront_5xx_evaluation_periods" {
  description = "Evaluation periods for the CloudFront 5xx error rate alarm."
  type        = number
  default     = 2
}
