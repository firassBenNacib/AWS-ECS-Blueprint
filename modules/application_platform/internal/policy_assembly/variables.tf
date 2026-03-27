variable "runtime" {
  type = object({
    runtime_mode_is_micro           = bool
    cost_optimized_dev_tier_enabled = bool
    project_name                    = string
    environment_name                = string
    aws_region                      = string
    rds_db_name                     = string
    rds_username                    = string
  })
}

variable "backend" {
  type = object({
    backend_env                     = map(string)
    backend_secret_arns             = map(string)
    backend_rds_secret_env_var_name = string
    backend_container_image         = string
    allowed_image_registries_final  = list(string)
    microservice_allowed_registries = list(string)
  })
}

variable "app_data" {
  type = object({
    address                = string
    master_user_secret_arn = string
  })
}

variable "ecs_services" {
  type = map(any)
}
