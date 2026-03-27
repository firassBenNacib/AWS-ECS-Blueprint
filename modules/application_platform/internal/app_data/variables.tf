variable "environment" {
  description = "Normalized environment naming inputs for data resources."
  type = object({
    name          = string
    enable_suffix = bool
  })
}

variable "data" {
  description = "Resolved RDS configuration inputs."
  type        = any
}
