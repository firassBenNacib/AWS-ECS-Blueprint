variable "environment_domain" {
  description = "Base domain used for environment-derived aliases (for example: example.com)."
  type        = string

  validation {
    condition     = trimspace(var.environment_domain) != ""
    error_message = "environment_domain must be set in this deployable configuration."
  }
}

variable "environment_name_override" {
  description = "Optional explicit environment name used for naming and DNS derivation. Leave null to derive it from the current Terraform context."
  type        = string
  default     = null
}

variable "enable_environment_suffix" {
  description = "Append the effective environment name to shared resource names. Keep enabled for dedicated per-environment roots."
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

variable "enable_cost_optimized_dev_tier" {
  description = "Enable a lower-cost dev tier profile that reduces account-level controls, forces private-app NAT to disabled, and uses single-AZ RDS."
  type        = bool
  default     = false
}

variable "enable_security_baseline" {
  description = "Enable account-level production security baseline controls (CloudTrail, Config, GuardDuty, Security Hub, Access Analyzer)."
  type        = bool
  default     = true
}

variable "enable_account_security_controls" {
  description = "When true, this root owns account-level security controls in addition to workload infrastructure."
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config recorder and delivery channel inside the account-level security baseline."
  type        = bool
  default     = true
}

variable "securityhub_standards_arns" {
  description = "Optional explicit Security Hub standard subscription ARNs. Leave empty to use AWS Foundational + CIS defaults."
  type        = list(string)
  default     = []
}

variable "security_baseline_log_retention_days" {
  description = "Retention in days for account-level security baseline log storage lifecycle."
  type        = number
  default     = 365

  validation {
    condition     = var.security_baseline_log_retention_days >= 1 && var.security_baseline_log_retention_days == floor(var.security_baseline_log_retention_days)
    error_message = "security_baseline_log_retention_days must be an integer >= 1."
  }
}

variable "security_findings_sns_topic_arn" {
  description = "Optional existing SNS topic ARN that receives high/critical GuardDuty and Security Hub findings. When null, a managed topic is created."
  type        = string
  default     = null
}

variable "security_findings_sns_subscriptions" {
  description = "Optional managed-topic subscriptions for security findings notifications."
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default = []
}

variable "enable_cloudtrail_data_events" {
  description = "Enable CloudTrail data event selectors for high-value resource telemetry."
  type        = bool
  default     = false
}

variable "cloudtrail_data_event_resources" {
  description = "CloudTrail data-event resource ARNs (for example S3 object data selectors like arn:aws:s3:::bucket-name/)."
  type        = list(string)
  default     = []
}

variable "enable_inspector" {
  description = "Enable Amazon Inspector for account-level vulnerability scanning."
  type        = bool
  default     = true
}

variable "inspector_resource_types" {
  description = "Amazon Inspector resource types to enable for account-level vulnerability scanning."
  type        = list(string)
  default     = ["ECR", "EC2"]
}

variable "enable_aws_backup" {
  description = "Enable AWS Backup plan/selection for the primary RDS instance."
  type        = bool
  default     = true
}

variable "security_baseline_enable_object_lock" {
  description = "Enable S3 Object Lock on the security baseline audit-log bucket."
  type        = bool
  default     = false
}

variable "aws_backup_vault_name" {
  description = "Optional AWS Backup vault base name. When null, an environment-prefixed default is used."
  type        = string
  default     = null
}

variable "aws_backup_schedule_expression" {
  description = "Cron expression for the AWS Backup RDS backup rule."
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "aws_backup_retention_days" {
  description = "Retention period in days for primary-region recovery points."
  type        = number
  default     = 35

  validation {
    condition     = var.aws_backup_retention_days >= 1 && var.aws_backup_retention_days == floor(var.aws_backup_retention_days)
    error_message = "aws_backup_retention_days must be an integer >= 1."
  }
}

variable "aws_backup_start_window_minutes" {
  description = "Start window in minutes for the AWS Backup rule."
  type        = number
  default     = 60

  validation {
    condition     = var.aws_backup_start_window_minutes >= 60 && var.aws_backup_start_window_minutes == floor(var.aws_backup_start_window_minutes)
    error_message = "aws_backup_start_window_minutes must be an integer >= 60."
  }
}

variable "aws_backup_completion_window_minutes" {
  description = "Completion window in minutes for the AWS Backup rule."
  type        = number
  default     = 180

  validation {
    condition     = var.aws_backup_completion_window_minutes >= 60 && var.aws_backup_completion_window_minutes == floor(var.aws_backup_completion_window_minutes)
    error_message = "aws_backup_completion_window_minutes must be an integer >= 60."
  }
}

variable "aws_backup_cross_region_copy_enabled" {
  description = "When true, copy AWS Backup recovery points to a DR-region backup vault."
  type        = bool
  default     = true
}

variable "aws_backup_copy_retention_days" {
  description = "Retention period in days for copied DR-region recovery points."
  type        = number
  default     = 35

  validation {
    condition     = var.aws_backup_copy_retention_days >= 1 && var.aws_backup_copy_retention_days == floor(var.aws_backup_copy_retention_days)
    error_message = "aws_backup_copy_retention_days must be an integer >= 1."
  }
}

variable "enable_budget_alerts" {
  description = "Whether optional AWS Budgets alerts should be created for monthly spend visibility."
  type        = bool
  default     = false
}

variable "budget_alert_email_addresses" {
  description = "Email addresses subscribed to AWS Budgets alerts."
  type        = list(string)
  default     = []
}

variable "budget_alert_topic_arns" {
  description = "SNS topic ARNs subscribed to AWS Budgets alerts."
  type        = list(string)
  default     = []
}

variable "budget_alert_threshold_percentages" {
  description = "Percentage thresholds that trigger ACTUAL spend AWS Budgets notifications."
  type        = list(number)
  default     = [80, 100]

  validation {
    condition = (
      length(var.budget_alert_threshold_percentages) > 0 &&
      alltrue([for value in var.budget_alert_threshold_percentages : value > 0])
    )
    error_message = "budget_alert_threshold_percentages must contain one or more positive numbers."
  }
}

variable "budget_total_monthly_limit" {
  description = "Optional total monthly budget limit."
  type        = number
  default     = null
}

variable "budget_cloudfront_monthly_limit" {
  description = "Optional monthly budget limit for Amazon CloudFront."
  type        = number
  default     = null
}

variable "budget_vpc_monthly_limit" {
  description = "Optional monthly budget limit for Amazon Virtual Private Cloud charges, including NAT-related spend."
  type        = number
  default     = null
}

variable "budget_rds_monthly_limit" {
  description = "Optional monthly budget limit for Amazon Relational Database Service."
  type        = number
  default     = null
}

variable "vpc_flow_logs_retention_days" {
  description = "CloudWatch log retention days for VPC Flow Logs."
  type        = number
  default     = 365

  validation {
    condition     = var.vpc_flow_logs_retention_days >= 1 && var.vpc_flow_logs_retention_days == floor(var.vpc_flow_logs_retention_days)
    error_message = "vpc_flow_logs_retention_days must be an integer >= 1."
  }
}

variable "vpc_flow_logs_kms_key_id" {
  description = "Optional KMS key ARN for VPC Flow Logs encryption. When null, flow logs are not KMS-encrypted."
  type        = string
  default     = null
}

variable "lockdown_default_security_group" {
  description = "When true, remove all ingress/egress rules from the default security group of the dedicated VPC."
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region for primary resources."
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "AWS region for disaster-recovery replicas (S3 replication targets)."
  type        = string
  default     = "us-west-2"
}
