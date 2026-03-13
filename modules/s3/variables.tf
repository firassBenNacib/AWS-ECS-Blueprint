variable "bucket_name" {
  description = "S3 bucket name for hosting frontend"
  type        = string
}

variable "force_destroy" {
  description = "Allow destroying non-empty S3 bucket"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "enable_kms_encryption" {
  description = "Use SSE-KMS for bucket encryption instead of SSE-S3"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for SSE-KMS encryption"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_kms_encryption || (var.kms_key_id != null && trimspace(var.kms_key_id) != "")
    error_message = "kms_key_id must be set when enable_kms_encryption=true."
  }
}

variable "access_logging_target_bucket_name" {
  description = "Optional bucket name receiving S3 server access logs for this bucket."
  type        = string
  default     = null
}

variable "enable_access_logging" {
  description = "Enable S3 server access logging for this bucket."
  type        = bool
  default     = false

  validation {
    condition = (
      !var.enable_access_logging ||
      (var.access_logging_target_bucket_name != null && trimspace(var.access_logging_target_bucket_name) != "")
    )
    error_message = "access_logging_target_bucket_name must be set when enable_access_logging=true."
  }
}

variable "access_logging_target_prefix" {
  description = "Prefix used for S3 server access logs when access logging is enabled."
  type        = string
  default     = "s3-access/frontend/"
}

variable "access_logging_prerequisite_ids" {
  description = "Opaque dependency IDs that must exist before access logging is configured."
  type        = list(string)
  default     = []
}

variable "replication_role_arn" {
  description = "Optional IAM role ARN used for bucket replication."
  type        = string
  default     = null
}

variable "enable_replication" {
  description = "Enable cross-region bucket replication."
  type        = bool
  default     = false

  validation {
    condition = (
      !var.enable_replication ||
      (
        var.replication_role_arn != null &&
        trimspace(var.replication_role_arn) != "" &&
        var.replication_destination_bucket_arn != null &&
        trimspace(var.replication_destination_bucket_arn) != "" &&
        var.replication_replica_kms_key_id != null &&
        trimspace(var.replication_replica_kms_key_id) != ""
      )
    )
    error_message = "replication_role_arn, replication_destination_bucket_arn, and replication_replica_kms_key_id must be set when enable_replication=true."
  }
}

variable "replication_destination_bucket_arn" {
  description = "Optional destination bucket ARN for cross-region replication."
  type        = string
  default     = null
}

variable "replication_replica_kms_key_id" {
  description = "Optional replica-region KMS key ARN used for replicated objects."
  type        = string
  default     = null
}

variable "replication_prerequisite_ids" {
  description = "Opaque dependency IDs that must exist before replication is configured."
  type        = list(string)
  default     = []
}

variable "enable_lifecycle" {
  description = "Enable lifecycle policy on the bucket"
  type        = bool
  default     = false
}

variable "lifecycle_expiration_days" {
  description = "Optional expiration age for current objects"
  type        = number
  default     = null
}

variable "lifecycle_noncurrent_expiration_days" {
  description = "Optional expiration age for noncurrent object versions"
  type        = number
  default     = 30
}

variable "lifecycle_abort_incomplete_multipart_upload_days" {
  description = "Abort incomplete multipart uploads after this many days"
  type        = number
  default     = 7

  validation {
    condition     = var.lifecycle_abort_incomplete_multipart_upload_days >= 1 && var.lifecycle_abort_incomplete_multipart_upload_days == floor(var.lifecycle_abort_incomplete_multipart_upload_days)
    error_message = "lifecycle_abort_incomplete_multipart_upload_days must be an integer >= 1."
  }
}
