variable "environment" {
  description = "Normalized environment naming inputs for network and security resources."
  type = object({
    name          = string
    enable_suffix = bool
  })
}

variable "network" {
  description = "Resolved network inputs for the shared VPC module."
  type        = any
}

variable "security" {
  description = "Resolved security-group inputs for runtime modes."
  type        = any
}
