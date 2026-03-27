variable "project_name" {
  description = "Required project name applied to resource names, tags, and internal DNS defaults."
  type        = string
}

variable "resource_contract_tags" {
  description = "Additional root-level contract tags merged into provider default tags."
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "app-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "public_app_subnet_cidrs" {
  description = "CIDR blocks for public edge subnets (ALB/NAT gateways)"
  type        = list(string)
  default     = []
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (backend service tasks)"
  type        = list(string)
  default     = []
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  default     = []
}

variable "bucket_name" {
  description = "Name of the frontend S3 bucket"
  type        = string
}

variable "s3_force_destroy" {
  description = "Allow destroying non-empty frontend S3 bucket (not recommended for production)"
  type        = bool
  default     = false
}

variable "destroy_mode_enabled" {
  description = "Relax deletion protections and enable force-destroy semantics for repeatable teardown."
  type        = bool
  default     = false
}

variable "s3_versioning_enabled" {
  description = "Enable frontend bucket versioning"
  type        = bool
  default     = true
}

variable "s3_kms_key_id" {
  description = "Optional KMS key ARN for primary-region S3 encryption. When null, a managed key is created."
  type        = string
  default     = null
}

variable "dr_s3_kms_key_id" {
  description = "Optional KMS key ARN for DR-region S3 replica encryption. When null, a managed key is created in the DR region."
  type        = string
  default     = null
}

variable "enable_s3_lifecycle" {
  description = "Enable lifecycle rules on the frontend S3 bucket"
  type        = bool
  default     = false
}

variable "s3_lifecycle_expiration_days" {
  description = "Optional expiration age (days) for current frontend S3 objects"
  type        = number
  default     = null
}

variable "s3_lifecycle_noncurrent_expiration_days" {
  description = "Optional expiration age (days) for noncurrent frontend S3 object versions"
  type        = number
  default     = 30
}

variable "s3_lifecycle_abort_incomplete_multipart_upload_days" {
  description = "Abort incomplete multipart uploads in frontend S3 bucket after this many days"
  type        = number
  default     = 7

  validation {
    condition     = var.s3_lifecycle_abort_incomplete_multipart_upload_days >= 1 && var.s3_lifecycle_abort_incomplete_multipart_upload_days == floor(var.s3_lifecycle_abort_incomplete_multipart_upload_days)
    error_message = "s3_lifecycle_abort_incomplete_multipart_upload_days must be an integer >= 1."
  }
}
