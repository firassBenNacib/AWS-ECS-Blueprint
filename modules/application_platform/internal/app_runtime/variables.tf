variable "environment" {
  description = "Normalized environment naming inputs for runtime resources."
  type = object({
    name          = string
    enable_suffix = bool
  })
}

variable "runtime" {
  description = "Resolved shared runtime inputs."
  type        = any
}

variable "single_backend" {
  description = "Resolved single-backend ECS inputs."
  type        = any
}

variable "microservices" {
  description = "Resolved gateway-microservices ECS inputs."
  type        = any
}

variable "networking" {
  description = "Resolved security-group outputs from the networking wrapper."
  type        = any
}

variable "edge" {
  description = "Resolved backend edge outputs consumed by runtime services."
  type        = any
}
