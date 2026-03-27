variable "name_prefix" {
  description = "Prefix used to name security baseline resources"
  type        = string
}

variable "log_bucket_name" {
  description = "S3 bucket name used for CloudTrail and AWS Config delivery"
  type        = string
}

variable "access_logs_bucket_name" {
  description = "Optional central S3 access-log sink bucket name used for baseline log bucket server access logs"
  type        = string
  default     = null
}

variable "access_logs_bucket_name_dr" {
  description = "Optional DR-region S3 access-log sink bucket name used for the replicated baseline log bucket server access logs."
  type        = string
  default     = null
}

variable "cloudtrail_retention_days" {
  description = "Retention in days for lifecycle cleanup in the security baseline log bucket"
  type        = number
  default     = 365
}

variable "enable_security_hub" {
  description = "Enable Security Hub account integration and standards subscriptions"
  type        = bool
  default     = true
}

variable "securityhub_standards" {
  description = "Security Hub standards ARNs to subscribe to"
  type        = list(string)
  default     = []
}

variable "enable_access_analyzer" {
  description = "Enable IAM Access Analyzer"
  type        = bool
  default     = true
}

variable "security_findings_sns_topic_arn" {
  description = "Optional existing SNS topic ARN for GuardDuty/Security Hub high/critical findings. When null, a managed topic is created."
  type        = string
  default     = null
}

variable "security_findings_sns_subscriptions" {
  description = "Optional managed-topic SNS subscriptions for security findings."
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default = []
}

variable "enable_cloudtrail_data_events" {
  description = "Enable CloudTrail data event selectors for high-value resources."
  type        = bool
  default     = false
}

variable "cloudtrail_data_event_resources" {
  description = "CloudTrail data-event resource ARNs (for example arn:aws:s3:::bucket-name/)."
  type        = list(string)
  default     = []
}

variable "enable_inspector" {
  description = "Enable Amazon Inspector account scanning."
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config recorder and delivery channel."
  type        = bool
  default     = true
}

variable "enable_ecs_exec_audit_alerts" {
  description = "Enable EventBridge alerts for ECS Exec shell access observed via CloudTrail."
  type        = bool
  default     = false
}

variable "log_bucket_dr_name" {
  description = "Optional DR-region replica bucket name for security baseline logs. When unset, Terraform derives one from log_bucket_name and dr_region."
  type        = string
  default     = null
}

variable "object_lock_days" {
  description = "S3 Object Lock GOVERNANCE-mode retention period in days for the CloudTrail/Config log bucket. Prevents accidental deletion of audit logs."
  type        = number
  default     = 365

  validation {
    condition     = var.object_lock_days >= 1 && var.object_lock_days == floor(var.object_lock_days)
    error_message = "object_lock_days must be an integer >= 1."
  }
}

variable "enable_log_bucket_object_lock" {
  description = "Enable S3 Object Lock on the primary security baseline log bucket."
  type        = bool
  default     = false
}

variable "log_bucket_force_destroy" {
  description = "Force deletion of security baseline log buckets during teardown."
  type        = bool
  default     = false
}
