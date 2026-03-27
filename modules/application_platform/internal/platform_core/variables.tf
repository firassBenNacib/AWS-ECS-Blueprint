variable "environment" {
  description = "Normalized environment and Route53 inputs for the shared platform-core layer."
  type = object({
    name                  = string
    domain                = string
    route53_zone_id_input = string
    route53_zone_strategy = string
    live_validation_mode  = bool
    live_validation_label = string
  })
}

variable "origin_auth" {
  description = "Origin-auth SSM parameter inputs."
  type = object({
    enabled                     = bool
    header_ssm_parameter_name   = string
    previous_ssm_parameter_name = string
  })
}

variable "kms" {
  description = "KMS configuration inputs owned by the application_platform wrapper."
  type = object({
    project_name              = string
    aws_region                = string
    dr_region                 = string
    create_primary_s3_kms_key = bool
    create_dr_s3_kms_key      = bool
    s3_kms_key_id             = string
    dr_s3_kms_key_id          = string
    enable_ecs_exec           = bool
  })
}

variable "guardrails" {
  description = "Resolved guardrail inputs from the wrapper."
  type        = any
}
