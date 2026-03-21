data "aws_region" "current" {}

locals {
  environment_name = (
    var.environment_name_override != null && trimspace(var.environment_name_override) != ""
  ) ? trimspace(var.environment_name_override) : terraform.workspace
  suffix = var.enable_environment_suffix ? "-${local.environment_name}" : ""

  cluster_name_final        = "${var.cluster_name}${local.suffix}"
  service_name_final        = "${var.service_name}${local.suffix}"
  task_family_final         = "${var.task_family}${local.suffix}"
  execution_role_name       = "${var.execution_role_name}${local.suffix}"
  task_role_name            = "${var.task_role_name}${local.suffix}"
  log_group_name_final      = "/aws/ecs/${var.log_group_name}${local.suffix}"
  exec_log_group_name_final = "/aws/ecs/exec/${var.exec_log_group_name}${local.suffix}"
  autoscaling_target_name   = "service/${local.cluster_name_final}/${local.service_name_final}"

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

  container_definitions = [
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
      user                   = var.container_user
      linuxParameters = {
        capabilities = {
          add  = []
          drop = var.drop_capabilities
        }
      }
      environment    = local.container_environment
      mountPoints    = []
      secrets        = local.container_secrets
      systemControls = []
      volumesFrom    = []
    }
  ]
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
  name               = local.execution_role_name
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
        "secretsmanager:GetSecretValue"
      ]
      resources = distinct(values(var.secret_arns))
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

  name   = "${local.execution_role_name}-secrets"
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

resource "aws_iam_role_policy_attachment" "execution_secrets" {
  count = length(var.secret_arns) > 0 || length(var.secret_kms_key_arns) > 0 ? 1 : 0

  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution_secrets[0].arn
}

resource "aws_iam_role" "task" {
  name               = local.task_role_name
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

  name   = "${local.task_role_name}-exec-kms"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_exec_kms[0].json
}

resource "aws_iam_role_policy" "task_inline" {
  count = var.task_role_policy_json == null ? 0 : 1

  name   = "${local.task_role_name}-inline"
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name_final
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id
}

resource "aws_cloudwatch_log_group" "exec" {
  count = var.enable_execute_command ? 1 : 0

  name              = local.exec_log_group_name_final
  retention_in_days = var.exec_log_retention_days
  kms_key_id        = var.exec_kms_key_arn
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name_final

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  dynamic "configuration" {
    for_each = var.enable_execute_command ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = var.exec_kms_key_arn
        logging    = "OVERRIDE"

        log_configuration {
          cloud_watch_encryption_enabled = true
          cloud_watch_log_group_name     = aws_cloudwatch_log_group.exec[0].name
        }
      }
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.task_family_final
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = jsonencode(local.container_definitions)
}

resource "aws_ecs_service" "this" {
  name                              = local.service_name_final
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  alarms {
    alarm_names = [
      aws_cloudwatch_metric_alarm.deploy_5xx.alarm_name,
      aws_cloudwatch_metric_alarm.deploy_unhealthy_hosts.alarm_name
    ]
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_iam_role_policy_attachment.execution_managed]
}

resource "aws_appautoscaling_target" "service" {
  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = local.autoscaling_target_name
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.service_name_final}-cpu-target"
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
  name               = "${local.service_name_final}-memory-target"
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
  count = var.alb_request_count_target_value != null ? 1 : 0

  name               = "${local.service_name_final}-alb-request-count-target"
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
  alarm_name          = "${local.service_name_final}-deploy-target-5xx"
  alarm_description   = "Rollback deployment when backend target 5xx errors breach threshold."
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
  alarm_name          = "${local.service_name_final}-deploy-unhealthy-hosts"
  alarm_description   = "Rollback deployment when target unhealthy host count breaches threshold."
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
