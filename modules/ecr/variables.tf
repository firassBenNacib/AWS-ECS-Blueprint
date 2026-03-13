variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "max_image_count" {
  description = "Maximum number of images retained by lifecycle policy"
  type        = number
  default     = 30
}

variable "encryption_kms_key_arn" {
  description = "Optional KMS key ARN for ECR encryption. When null, alias/aws/ecr is used."
  type        = string
  default     = null
}
