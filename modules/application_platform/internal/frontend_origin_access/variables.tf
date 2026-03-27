variable "frontend" {
  description = "Resolved frontend bucket-policy inputs."
  type = object({
    runtime_is_s3                = bool
    frontend_primary_bucket_name = string
    frontend_primary_bucket_arn  = string
    frontend_dr_bucket_name      = string
    frontend_dr_bucket_arn       = string
    distribution_arn             = string
  })
}
