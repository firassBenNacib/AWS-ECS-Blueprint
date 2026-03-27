variable "aws_region" {
  description = "Primary AWS region for validation ALB certificates and SSM parameters."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used in generated validation tfvars and parameter paths."
  type        = string
  default     = "example-app"
}

variable "environment_domain" {
  description = "Base public environment domain used by the app roots."
  type        = string
  default     = "example.com"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID used for ACM DNS validation and app aliases."
  type        = string
  default     = "Z111111EXAMPLE"
}

variable "validation_backend_image" {
  description = "Digest-pinned public validation image used in generated live-validation tfvars."
  type        = string
  default     = "docker.io/library/nginx@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10"
}

variable "validation_allowed_image_registries" {
  description = "Approved image repository prefixes used in generated live-validation tfvars."
  type        = list(string)
  default     = ["docker.io/library/nginx"]
}

variable "prod_validation_dns_label" {
  description = "Stable DNS label used for prod-app live validation."
  type        = string
  default     = "lv-prod"
}

variable "nonprod_validation_dns_label" {
  description = "Stable DNS label used for nonprod-app live validation."
  type        = string
  default     = "lv-nonprod"
}

variable "prod_cloudfront_logs_bucket_name" {
  description = "Stable CloudFront logs bucket name used in generated prod validation tfvars."
  type        = string
  default     = ""
}

variable "nonprod_cloudfront_logs_bucket_name" {
  description = "Stable CloudFront logs bucket name used in generated nonprod validation tfvars."
  type        = string
  default     = ""
}

variable "prod_bucket_name" {
  description = "Frontend S3 bucket base name used in generated prod validation tfvars."
  type        = string
  default     = ""
}

variable "nonprod_bucket_name" {
  description = "Frontend S3 bucket base name used in generated nonprod validation tfvars."
  type        = string
  default     = ""
}
