locals {
  ecs_services_final = var.runtime.runtime_mode_is_micro ? {
    for service_name, service in var.ecs_services :
    service_name => {
      image                                        = trimspace(service.image)
      container_port                               = service.container_port
      container_name                               = coalesce(try(service.container_name, null), service_name)
      public                                       = coalesce(try(service.public, null), false)
      desired_count                                = var.runtime.cost_optimized_dev_tier_enabled ? 1 : coalesce(try(service.desired_count, null), 1)
      min_count                                    = var.runtime.cost_optimized_dev_tier_enabled ? 1 : coalesce(try(service.min_count, null), 1)
      max_count                                    = var.runtime.cost_optimized_dev_tier_enabled ? 1 : coalesce(try(service.max_count, null), 2)
      cpu                                          = coalesce(try(service.cpu, null), 512)
      memory                                       = coalesce(try(service.memory, null), 1024)
      alb_request_count_target_value               = try(service.alb_request_count_target_value, null)
      alb_request_count_scale_in_cooldown_seconds  = coalesce(try(service.alb_request_count_scale_in_cooldown_seconds, null), 300)
      alb_request_count_scale_out_cooldown_seconds = coalesce(try(service.alb_request_count_scale_out_cooldown_seconds, null), 60)
      health_check_grace_period_seconds            = coalesce(try(service.health_check_grace_period_seconds, null), 60)
      health_check_path                            = coalesce(try(service.health_check_path, null), "/health")
      container_user                               = try(service.container_user, null)
      readonly_root_fs                             = coalesce(try(service.readonly_root_fs, null), true)
      drop_capabilities                            = coalesce(try(service.drop_capabilities, null), ["ALL"])
      env = {
        for env_key, env_value in coalesce(try(service.env, null), {}) :
        env_key => replace(
          replace(
            replace(env_value, "__RDS_ENDPOINT__", local.microservice_env_placeholders["__RDS_ENDPOINT__"]),
            "__RDS_DB_NAME__",
            local.microservice_env_placeholders["__RDS_DB_NAME__"]
          ),
          "__SMTP_HOST__",
          local.microservice_env_placeholders["__SMTP_HOST__"]
        )
      }
      secret_arns = {
        for secret_key, secret_value in coalesce(try(service.secret_arns, null), {}) :
        secret_key => replace(
          secret_value,
          "__RDS_MASTER_PASSWORD_SECRET_ARN__",
          local.microservice_secret_placeholders["__RDS_MASTER_PASSWORD_SECRET_ARN__"]
        )
      }
      secret_kms_key_arns               = coalesce(try(service.secret_kms_key_arns, null), [])
      task_role_policy_json             = try(service.task_role_policy_json, null)
      log_group_name                    = coalesce(try(service.log_group_name, null), "/aws/ecs/${var.runtime.project_name}-${service_name}-${var.runtime.environment_name}")
      log_retention_days                = coalesce(try(service.log_retention_days, null), 30)
      log_kms_key_id                    = try(service.log_kms_key_id, null)
      entrypoint                        = coalesce(try(service.entrypoint, null), [])
      command                           = coalesce(try(service.command, null), [])
      mount_points                      = coalesce(try(service.mount_points, null), [])
      task_volumes                      = coalesce(try(service.task_volumes, null), [])
      health_check_command              = coalesce(try(service.health_check_command, null), [])
      health_check_interval_seconds     = coalesce(try(service.health_check_interval_seconds, null), 30)
      health_check_timeout_seconds      = coalesce(try(service.health_check_timeout_seconds, null), 5)
      health_check_retries              = coalesce(try(service.health_check_retries, null), 3)
      health_check_start_period_seconds = coalesce(try(service.health_check_start_period_seconds, null), 15)
      assign_public_ip                  = coalesce(try(service.assign_public_ip, null), false)
      enable_service_discovery          = coalesce(try(service.enable_service_discovery, null), true)
      discovery_name                    = coalesce(try(service.discovery_name, null), service_name)
      extra_egress                      = coalesce(try(service.extra_egress, null), [])
    }
  } : {}

  public_service_keys = var.runtime.runtime_mode_is_micro ? sort([
    for service_name, service in var.ecs_services : service_name if coalesce(try(service.public, null), false)
  ]) : []
  public_service_key   = length(local.public_service_keys) > 0 ? local.public_service_keys[0] : null
  public_service_input = local.public_service_key != null ? var.ecs_services[local.public_service_key] : null

  microservice_image_repositories = var.runtime.runtime_mode_is_micro ? {
    for service_name, service in local.ecs_services_final :
    service_name => split("@", service.image)[0]
  } : {}
}
