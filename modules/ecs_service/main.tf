terraform {
  required_version = ">= 1.8.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

data "aws_region" "current" {}

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

data "aws_iam_policy_document" "execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = var.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role.json
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  count = length(var.secret_arns) > 0 || length(var.secret_kms_key_arns) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []
    content {
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      resources = local.secret_policy_resources
    }
  }

  dynamic "statement" {
    for_each = length(var.secret_kms_key_arns) > 0 ? [1] : []
    content {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = var.secret_kms_key_arns
    }
  }
}

resource "aws_iam_policy" "execution_secrets" {
  count = length(var.secret_arns) > 0 || length(var.secret_kms_key_arns) > 0 ? 1 : 0

  name   = "${var.execution_role_name}-secrets"
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

resource "aws_iam_role_policy_attachment" "execution_secrets" {
  count = length(var.secret_arns) > 0 || length(var.secret_kms_key_arns) > 0 ? 1 : 0

  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution_secrets[0].arn
}

resource "aws_iam_role" "task" {
  name               = var.task_role_name
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role.json
}

data "aws_iam_policy_document" "task_exec_kms" {
  count = var.enable_execute_command && var.exec_kms_key_arn != null ? 1 : 0

  statement {
    actions   = ["kms:Decrypt"]
    resources = [var.exec_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "task_exec_kms" {
  count = var.enable_execute_command && var.exec_kms_key_arn != null ? 1 : 0

  name   = "${var.task_role_name}-exec-kms"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_exec_kms[0].json
}

resource "aws_iam_role_policy" "task_inline" {
  count = var.task_role_policy_json == null ? 0 : 1

  name   = "${var.task_role_name}-inline"
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id
}

resource "aws_cloudwatch_log_group" "exec" {
  count = var.enable_execute_command && var.exec_log_group_name != null ? 1 : 0

  name              = var.exec_log_group_name
  retention_in_days = var.exec_log_retention_days
  kms_key_id        = var.exec_kms_key_arn
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = jsonencode([local.container_definition])

  dynamic "volume" {
    for_each = {
      for volume in var.task_volumes : volume.name => volume
    }
    content {
      configure_at_launch = false
      name                = volume.value.name
    }
  }
}

resource "aws_ecs_service" "this" {
  name                              = var.service_name
  cluster                           = var.cluster_arn
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = local.enable_load_balancer ? var.health_check_grace_period_seconds : null

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "alarms" {
    for_each = local.enable_deploy_alarms ? [1] : []
    content {
      alarm_names = [
        aws_cloudwatch_metric_alarm.deploy_5xx[0].alarm_name,
        aws_cloudwatch_metric_alarm.deploy_unhealthy_hosts[0].alarm_name
      ]
      enable   = true
      rollback = true
    }
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.service_security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = local.enable_load_balancer ? [1] : []
    content {
      target_group_arn = var.load_balancer_target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = local.enable_service_discovery ? [1] : []
    content {
      registry_arn = var.service_discovery_registry_arn
    }
  }

  depends_on = [aws_iam_role_policy_attachment.execution_managed]
}

resource "aws_appautoscaling_target" "service" {
  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.service_name}-cpu-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.cpu_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = var.scale_in_cooldown_seconds
    scale_out_cooldown = var.scale_out_cooldown_seconds
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.service_name}-memory-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.memory_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = var.scale_in_cooldown_seconds
    scale_out_cooldown = var.scale_out_cooldown_seconds
  }
}

resource "aws_appautoscaling_policy" "alb_request_count" {
  count = var.alb_request_count_target_value != null && var.target_group_arn_suffix != null ? 1 : 0

  name               = "${var.service_name}-alb-request-count-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.alb_request_count_target_value

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.alb_arn_suffix}/${var.target_group_arn_suffix}"
    }

    scale_in_cooldown  = var.alb_request_count_scale_in_cooldown_seconds
    scale_out_cooldown = var.alb_request_count_scale_out_cooldown_seconds
  }
}

resource "aws_cloudwatch_metric_alarm" "deploy_5xx" {
  count = local.enable_deploy_alarms ? 1 : 0

  alarm_name          = "${var.service_name}-deploy-target-5xx"
  alarm_description   = "Rollback deployment when target 5xx errors breach threshold."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = var.deploy_alarm_eval_periods
  threshold           = var.deploy_alarm_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "deploy_unhealthy_hosts" {
  count = local.enable_deploy_alarms ? 1 : 0

  alarm_name          = "${var.service_name}-deploy-unhealthy-hosts"
  alarm_description   = "Rollback deployment when unhealthy host count breaches threshold."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = var.deploy_alarm_eval_periods
  threshold           = var.deploy_alarm_unhealthy_hosts_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}
