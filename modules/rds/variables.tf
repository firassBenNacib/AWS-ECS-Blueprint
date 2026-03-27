variable "identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "app-rds"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "password" {
  description = "Master password (required only when manage_master_user_password=false)"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.manage_master_user_password || (var.password != null && trimspace(var.password) != "")
    error_message = "password must be set when manage_master_user_password=false."
  }
}

variable "manage_master_user_password" {
  description = "Enable RDS-managed master user password stored in Secrets Manager"
  type        = bool
  default     = true
}

variable "master_user_secret_kms_key_id" {
  description = "Optional KMS key ARN for RDS-managed master user secret"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "engine_version" {
  description = "RDS engine version for the MySQL instance."
  type        = string
  default     = "8.0.40"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for the RDS instance."
  type        = bool
  default     = true
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB for autoscaling. Set to 0 to disable."
  type        = number
  default     = 0
}

variable "backup_retention_period" {
  description = "RDS backup retention in days"
  type        = number
  default     = 14
}

variable "preferred_backup_window" {
  description = "Daily time range during which automated backups are created (UTC)."
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range during which system maintenance can occur (UTC)."
  type        = string
  default     = "sun:04:30-sun:05:30"
}

variable "final_snapshot_identifier" {
  description = "Optional final snapshot identifier used on instance deletion"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection on the RDS instance."
  type        = bool
  default     = true
}


variable "skip_final_snapshot" {
  description = "Skip the final snapshot on instance deletion."
  type        = bool
  default     = false
}

variable "enable_iam_database_auth" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "performance_insights_kms_key_id" {
  description = "Optional KMS key ARN for Performance Insights"
  type        = string
  default     = null
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights when the chosen DB engine/class combination supports it."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS Key ARN for encryption"
  type        = string
  default     = null
}

variable "rds_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "db_subnet_ids" {
  description = "Private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "enable_environment_suffix" {
  description = "Suffix RDS identifiers with environment"
  type        = bool
  default     = false
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for RDS naming. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}

variable "monitoring_interval_seconds" {
  description = "Enhanced monitoring interval in seconds (0 disables enhanced monitoring)"
  type        = number
  default     = 60
}

variable "enabled_cloudwatch_logs_exports" {
  description = "RDS log types exported to CloudWatch Logs"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}
