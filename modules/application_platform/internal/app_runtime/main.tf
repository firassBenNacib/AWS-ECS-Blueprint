module "ecr_backend" {
  count  = var.runtime.runtime_mode_is_single && var.single_backend.create_backend_ecr_repository ? 1 : 0
  source = "../../../ecr"

  repository_name        = var.single_backend.backend_ecr_repository_name_final
  max_image_count        = var.single_backend.backend_ecr_lifecycle_max_images
  encryption_kms_key_arn = var.single_backend.backend_ecr_kms_key_arn
}

resource "aws_cloudwatch_log_group" "microservices_exec" {
  count = var.runtime.runtime_mode_is_micro && var.runtime.enable_ecs_exec ? 1 : 0

  name              = var.runtime.microservices_exec_log_group_name
  retention_in_days = var.runtime.ecs_exec_log_retention_days
  kms_key_id        = var.runtime.ecs_exec_kms_key_arn_final
}

resource "aws_ecs_cluster" "microservices" {
  count = var.runtime.runtime_mode_is_micro ? 1 : 0

  name = var.runtime.microservices_cluster_name_final

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  dynamic "configuration" {
    for_each = var.runtime.enable_ecs_exec ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = var.runtime.ecs_exec_kms_key_arn_final
        logging    = "OVERRIDE"

        log_configuration {
          cloud_watch_encryption_enabled = true
          cloud_watch_log_group_name     = aws_cloudwatch_log_group.microservices_exec[0].name
        }
      }
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "microservices" {
  count = var.runtime.runtime_mode_is_micro ? 1 : 0

  name = var.runtime.service_discovery_namespace_name_final
  vpc  = var.runtime.selected_vpc_id
}

resource "aws_service_discovery_service" "microservices" {
  for_each = var.runtime.runtime_mode_is_micro ? {
    for service_name, service in var.microservices.ecs_services_final :
    service_name => service if service.enable_service_discovery
  } : {}

  name = each.value.discovery_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.microservices[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  lifecycle {
    ignore_changes = [
      health_check_custom_config
    ]
  }
}

module "ecs_backend" {
  count  = var.runtime.runtime_mode_is_single ? 1 : 0
  source = "../../../ecs_backend"

  private_subnet_ids        = var.runtime.selected_private_app_subnet_ids
  service_security_group_id = var.networking.backend_service_security_group_id
  target_group_arn          = var.edge.target_group_arn

  cluster_name                                 = var.single_backend.cluster_name
  service_name                                 = var.single_backend.service_name
  task_family                                  = var.single_backend.task_family
  execution_role_name                          = var.single_backend.execution_role_name
  task_role_name                               = var.single_backend.task_role_name
  container_name                               = var.single_backend.container_name
  container_image                              = var.single_backend.container_image
  container_port                               = var.single_backend.container_port
  container_user                               = var.single_backend.container_user
  readonly_root_fs                             = var.single_backend.readonly_root_fs
  drop_capabilities                            = var.single_backend.drop_capabilities
  task_cpu                                     = var.single_backend.task_cpu
  task_memory                                  = var.single_backend.task_memory
  desired_count                                = var.single_backend.desired_count
  min_count                                    = var.single_backend.min_count
  max_count                                    = var.single_backend.max_count
  cpu_target_value                             = var.single_backend.cpu_target_value
  memory_target_value                          = var.single_backend.memory_target_value
  alb_request_count_target_value               = var.single_backend.alb_request_count_target_value
  alb_request_count_scale_in_cooldown_seconds  = var.single_backend.alb_request_count_scale_in_cooldown_seconds
  alb_request_count_scale_out_cooldown_seconds = var.single_backend.alb_request_count_scale_out_cooldown_seconds
  health_check_grace_period_seconds            = var.single_backend.health_check_grace_period_seconds
  enable_execute_command                       = var.runtime.enable_ecs_exec
  exec_kms_key_arn                             = var.runtime.ecs_exec_kms_key_arn_final
  exec_log_group_name                          = var.single_backend.exec_log_group_name
  exec_log_retention_days                      = var.runtime.ecs_exec_log_retention_days
  alb_arn_suffix                               = var.edge.alb_arn_suffix
  target_group_arn_suffix                      = var.edge.target_group_arn_suffix
  deploy_alarm_5xx_threshold                   = var.runtime.backend_deploy_alarm_5xx_threshold
  deploy_alarm_unhealthy_hosts_threshold       = var.runtime.backend_deploy_alarm_unhealthy_hosts_threshold
  deploy_alarm_eval_periods                    = var.runtime.backend_deploy_alarm_eval_periods

  scale_in_cooldown_seconds  = var.runtime.backend_scale_in_cooldown_seconds
  scale_out_cooldown_seconds = var.runtime.backend_scale_out_cooldown_seconds

  environment           = var.single_backend.environment
  secret_arns           = var.single_backend.secret_arns
  secret_kms_key_arns   = var.single_backend.secret_kms_key_arns
  task_role_policy_json = var.single_backend.task_role_policy_json

  log_group_name            = var.single_backend.log_group_name
  log_retention_days        = var.single_backend.log_retention_days
  log_kms_key_id            = var.single_backend.log_kms_key_id
  enable_environment_suffix = var.environment.enable_suffix
  environment_name_override = var.environment.name
}

module "ecs_service" {
  for_each = var.runtime.runtime_mode_is_micro ? var.microservices.ecs_services_final : {}
  source   = "../../../ecs_service"

  cluster_arn  = aws_ecs_cluster.microservices[0].arn
  cluster_name = aws_ecs_cluster.microservices[0].name

  private_subnet_ids = var.runtime.selected_private_app_subnet_ids
  service_security_group_ids = concat(
    each.key == var.runtime.public_service_key ? [
      var.networking.microservices_gateway_security_group_id,
      var.networking.microservices_internal_security_group_id
      ] : [
      var.networking.microservices_internal_security_group_id
    ],
    contains(keys(var.networking.microservices_extra_egress_security_group_ids), each.key) ? [
      var.networking.microservices_extra_egress_security_group_ids[each.key]
    ] : []
  )

  service_name        = "${var.runtime.project_name}-${each.key}-${var.environment.name}"
  task_family         = "${var.runtime.project_name}-${each.key}-${var.environment.name}"
  execution_role_name = "${var.runtime.project_name}-${each.key}-${var.environment.name}-exec"
  task_role_name      = "${var.runtime.project_name}-${each.key}-${var.environment.name}-task"

  container_name    = each.value.container_name
  container_image   = each.value.image
  container_port    = each.value.container_port
  container_user    = each.value.container_user
  readonly_root_fs  = each.value.readonly_root_fs
  drop_capabilities = each.value.drop_capabilities

  task_cpu                               = each.value.cpu
  task_memory                            = each.value.memory
  desired_count                          = each.value.desired_count
  min_count                              = each.value.min_count
  max_count                              = each.value.max_count
  health_check_grace_period_seconds      = each.value.health_check_grace_period_seconds
  enable_execute_command                 = var.runtime.enable_ecs_exec
  exec_kms_key_arn                       = var.runtime.ecs_exec_kms_key_arn_final
  exec_log_group_name                    = null
  scale_in_cooldown_seconds              = var.runtime.backend_scale_in_cooldown_seconds
  scale_out_cooldown_seconds             = var.runtime.backend_scale_out_cooldown_seconds
  alb_arn_suffix                         = each.key == var.runtime.public_service_key ? var.edge.alb_arn_suffix : null
  target_group_arn_suffix                = each.key == var.runtime.public_service_key ? var.edge.target_group_arn_suffix : null
  enable_deploy_alarms                   = each.key == var.runtime.public_service_key
  deploy_alarm_5xx_threshold             = var.runtime.backend_deploy_alarm_5xx_threshold
  deploy_alarm_unhealthy_hosts_threshold = var.runtime.backend_deploy_alarm_unhealthy_hosts_threshold
  deploy_alarm_eval_periods              = var.runtime.backend_deploy_alarm_eval_periods

  environment           = each.value.env
  secret_arns           = each.value.secret_arns
  secret_kms_key_arns   = each.value.secret_kms_key_arns
  log_group_name        = each.value.log_group_name
  log_retention_days    = each.value.log_retention_days
  log_kms_key_id        = each.value.log_kms_key_id
  task_role_policy_json = each.value.task_role_policy_json

  enable_load_balancer           = each.key == var.runtime.public_service_key
  load_balancer_target_group_arn = each.key == var.runtime.public_service_key ? var.edge.target_group_arn : null
  service_discovery_registry_arn = try(aws_service_discovery_service.microservices[each.key].arn, null)

  entrypoint                        = each.value.entrypoint
  command                           = each.value.command
  mount_points                      = each.value.mount_points
  task_volumes                      = each.value.task_volumes
  health_check_command              = each.value.health_check_command
  health_check_interval_seconds     = each.value.health_check_interval_seconds
  health_check_timeout_seconds      = each.value.health_check_timeout_seconds
  health_check_retries              = each.value.health_check_retries
  health_check_start_period_seconds = each.value.health_check_start_period_seconds
  assign_public_ip                  = each.value.assign_public_ip
}
