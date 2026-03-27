variable "security" {
  description = "Resolved security baseline inputs."
  type        = any
}

variable "backup" {
  description = "Resolved AWS Backup inputs."
  type        = any
}

variable "budget" {
  description = "Resolved AWS Budgets alert inputs."
  type        = any
}
