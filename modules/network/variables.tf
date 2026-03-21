variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "app-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used by the network"
  type        = list(string)
}

variable "public_app_subnet_cidrs" {
  description = "CIDR blocks for public edge subnets (ALB/NAT)"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets (backend service tasks)"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private DB subnets"
  type        = list(string)
}

variable "flow_logs_retention_days" {
  description = "Retention days for the VPC Flow Logs CloudWatch log group"
  type        = number
  default     = 365
}

variable "flow_logs_kms_key_id" {
  description = "KMS key ARN used to encrypt VPC Flow Logs CloudWatch log group"
  type        = string
  default     = null
}

variable "flow_logs_name_prefix" {
  description = "Prefix used for VPC Flow Logs IAM and CloudWatch log-group names. Defaults to vpc_name when unset."
  type        = string
  default     = null
}

variable "lockdown_default_security_group" {
  description = "When true, removes all rules from the default security group for this VPC"
  type        = bool
  default     = true
}

variable "interface_endpoint_services" {
  description = "AWS service short names used to create Interface VPC Endpoints for private Fargate runtime dependencies."
  type        = list(string)
  default = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "sts",
    "secretsmanager",
    "kms"
  ]
}

variable "private_app_nat_mode" {
  description = "Private app subnet internet egress mode: required (all subnets via NAT), canary (single-subnet NAT route), or disabled (no NAT default route)."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "canary", "disabled"], var.private_app_nat_mode)
    error_message = "private_app_nat_mode must be one of required, canary, or disabled."
  }
}
