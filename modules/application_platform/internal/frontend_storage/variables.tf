variable "environment" {
  description = "Normalized environment naming inputs."
  type = object({
    name          = string
    enable_suffix = bool
  })
}

variable "frontend" {
  description = "Resolved frontend content storage inputs."
  type = object({
    runtime_is_s3                                    = bool
    bucket_name                                      = string
    dr_bucket_name                                   = string
    force_destroy                                    = bool
    versioning_enabled                               = bool
    enable_kms_encryption                            = bool
    primary_kms_key_arn                              = string
    dr_kms_key_arn                                   = string
    enable_access_logging                            = bool
    primary_access_logging_target_bucket_name        = string
    primary_access_logging_prerequisite_id           = string
    primary_access_logging_target_prefix             = string
    dr_access_logging_target_bucket_name             = string
    dr_access_logging_prerequisite_id                = string
    enable_lifecycle                                 = bool
    lifecycle_expiration_days                        = number
    lifecycle_noncurrent_expiration_days             = number
    lifecycle_abort_incomplete_multipart_upload_days = number
  })
}
