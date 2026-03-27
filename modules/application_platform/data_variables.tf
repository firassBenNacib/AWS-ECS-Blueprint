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

variable "rds_engine_version" {
  description = "RDS engine version for the workload MySQL instance."
  type        = string
  default     = "8.4.8"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for the workload RDS instance."
  type        = bool
  default     = true
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
  default     = ["audit", "error", "general", "slowquery"]
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

variable "enable_rds_master_user_password_rotation" {
  description = "Enable automatic rotation for the RDS-managed master user password."
  type        = bool
  default     = true
}

variable "rds_master_user_password_rotation_automatically_after_days" {
  description = "Rotation interval in days for the RDS-managed master user password."
  type        = number
  default     = 30

  validation {
    condition = (
      var.rds_master_user_password_rotation_automatically_after_days >= 1 &&
      var.rds_master_user_password_rotation_automatically_after_days == floor(var.rds_master_user_password_rotation_automatically_after_days)
    )
    error_message = "rds_master_user_password_rotation_automatically_after_days must be an integer >= 1."
  }
}

variable "route53_zone_id" {
  description = "Optional Route 53 public hosted zone ID override."
  type        = string
  default     = null
}

variable "route53_zone_strategy" {
  description = "How to resolve the public hosted zone when route53_zone_id is not set: explicit, autodiscover, or create."
  type        = string
  default     = "explicit"

  validation {
    condition     = contains(["explicit", "autodiscover", "create"], var.route53_zone_strategy)
    error_message = "route53_zone_strategy must be one of explicit, autodiscover, or create."
  }
}
