variable "name_prefix" {
  description = "Prefix used to name backup resources."
  type        = string
}

variable "enable_aws_backup" {
  description = "Enable AWS Backup vault, plan, and optional resource selection."
  type        = bool
  default     = true
}

variable "enable_backup_selection" {
  description = "Enable AWS Backup resource selection for the supplied resource ARNs."
  type        = bool
  default     = false

  validation {
    condition = (
      !var.enable_backup_selection ||
      length(var.backup_resource_arns) > 0
    )
    error_message = "backup_resource_arns must be populated when enable_backup_selection=true."
  }
}

variable "backup_vault_name" {
  description = "Optional AWS Backup vault base name. When unset, a name is derived from name_prefix."
  type        = string
  default     = null
}

variable "backup_dr_kms_key_arn" {
  description = "Optional existing KMS key ARN for the DR-region backup vault. Leave unset to let Terraform manage one."
  type        = string
  default     = null
}

variable "backup_schedule_expression" {
  description = "Cron expression for the AWS Backup rule."
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "backup_retention_days" {
  description = "Retention in days for primary-region recovery points."
  type        = number
  default     = 35
}

variable "backup_start_window_minutes" {
  description = "Backup job start window in minutes."
  type        = number
  default     = 60
}

variable "backup_completion_window_minutes" {
  description = "Backup job completion window in minutes."
  type        = number
  default     = 180
}

variable "backup_cross_region_copy_enabled" {
  description = "Enable cross-region copy of recovery points to the DR vault."
  type        = bool
  default     = true
}

variable "backup_copy_retention_days" {
  description = "Retention in days for DR copied recovery points."
  type        = number
  default     = 35
}

variable "backup_resource_arns" {
  description = "Resource ARNs selected by AWS Backup when enable_backup_selection=true."
  type        = list(string)
  default     = []
}
