variable "environment" {
  description = "Normalized environment naming inputs."
  type = object({
    name          = string
    enable_suffix = bool
  })
}

variable "buckets" {
  description = "Resolved bucket names and lifecycle posture."
  type = object({
    s3_access_logs_bucket_name     = string
    s3_access_logs_dr_bucket_name  = string
    alb_access_logs_bucket_name    = string
    alb_access_logs_dr_bucket_name = string
    cloudfront_logs_bucket_name    = string
    cloudfront_logs_dr_bucket_name = string
    force_destroy                  = bool
  })
}

variable "kms" {
  description = "Resolved KMS ARNs for primary and DR S3 encryption."
  type = object({
    s3_primary_kms_key_arn = string
    s3_dr_kms_key_arn      = string
  })
}

variable "logging" {
  description = "Logging and lifecycle settings for storage resources."
  type = object({
    enable_s3_access_logging                               = bool
    alb_access_logs_path                                   = string
    enable_cloudfront_logs_lifecycle                       = bool
    cloudfront_logs_expiration_days                        = number
    cloudfront_logs_abort_incomplete_multipart_upload_days = number
  })
}

variable "source_arns" {
  description = "Expected source bucket ARNs that may write server access logs."
  type = object({
    frontend_primary_bucket_arn = string
    frontend_dr_bucket_arn      = string
  })
}
