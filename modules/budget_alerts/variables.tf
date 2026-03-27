variable "enable_budget_alerts" {
  description = "Whether AWS Budgets alerts should be created."
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix used when naming budget resources."
  type        = string
}

variable "limit_unit" {
  description = "Currency unit used for budget limits."
  type        = string
  default     = "USD"
}

variable "notification_email_addresses" {
  description = "Email addresses subscribed to AWS Budgets notifications."
  type        = list(string)
  default     = []
}

variable "notification_topic_arns" {
  description = "SNS topic ARNs subscribed to AWS Budgets notifications."
  type        = list(string)
  default     = []
}

variable "alert_threshold_percentages" {
  description = "Percentage thresholds that trigger ACTUAL spend notifications."
  type        = list(number)
  default     = [80, 100]

  validation {
    condition = (
      length(var.alert_threshold_percentages) > 0 &&
      alltrue([for value in var.alert_threshold_percentages : value > 0])
    )
    error_message = "alert_threshold_percentages must contain one or more positive numbers."
  }
}

variable "total_monthly_limit" {
  description = "Optional total monthly cost limit for the account or environment scope."
  type        = number
  default     = null
}

variable "cloudfront_monthly_limit" {
  description = "Optional monthly cost limit for Amazon CloudFront."
  type        = number
  default     = null
}

variable "vpc_monthly_limit" {
  description = "Optional monthly cost limit for Amazon Virtual Private Cloud charges, including NAT-related spend."
  type        = number
  default     = null
}

variable "rds_monthly_limit" {
  description = "Optional monthly cost limit for Amazon Relational Database Service."
  type        = number
  default     = null
}
