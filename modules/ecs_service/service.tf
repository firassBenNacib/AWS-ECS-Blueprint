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
