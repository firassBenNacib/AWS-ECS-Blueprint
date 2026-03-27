locals {
  container_environment = [
    for key, value in var.environment : {
      name  = key
      value = value
    }
  ]

  container_secrets = [
    for key, value in var.secret_arns : {
      name      = key
      valueFrom = value
    }
  ]

  secret_policy_resources = distinct([
    for value in values(var.secret_arns) :
    can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:", value))
    ? replace(value, "/:[^:]*:[^:]*:[^:]*$/", "")
    : value
  ])

  enable_load_balancer     = var.enable_load_balancer
  enable_deploy_alarms     = var.enable_deploy_alarms
  enable_service_discovery = var.service_discovery_registry_arn != null && trimspace(var.service_discovery_registry_arn) != ""

  container_definition = merge(
    {
      name      = var.container_name
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "ecs"
        }
      }
      readonlyRootFilesystem = var.readonly_root_fs
      linuxParameters = {
        capabilities = {
          add  = []
          drop = var.drop_capabilities
        }
      }
      environment = local.container_environment
      mountPoints = [
        for mount_point in var.mount_points : {
          sourceVolume  = mount_point.source_volume
          containerPath = mount_point.container_path
          readOnly      = coalesce(try(mount_point.read_only, null), false)
        }
      ]
      secrets        = local.container_secrets
      systemControls = []
      volumesFrom    = []
    },
    var.container_user != null && trimspace(var.container_user) != "" ? { user = var.container_user } : {},
    length(var.entrypoint) > 0 ? { entryPoint = var.entrypoint } : {},
    length(var.command) > 0 ? { command = var.command } : {},
    length(var.health_check_command) > 0 ? {
      healthCheck = {
        command     = var.health_check_command
        interval    = var.health_check_interval_seconds
        timeout     = var.health_check_timeout_seconds
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period_seconds
      }
    } : {}
  )
}
