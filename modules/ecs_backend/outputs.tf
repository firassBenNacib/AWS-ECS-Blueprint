output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ECS service ARN"
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "Latest ECS task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "service_security_group_id" {
  description = "Security group ID attached to ECS tasks"
  value       = var.service_security_group_id
}

output "execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.task.arn
}

output "deployment_alarm_names" {
  description = "CloudWatch alarms attached to ECS deployment rollback."
  value = [
    aws_cloudwatch_metric_alarm.deploy_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.deploy_unhealthy_hosts.alarm_name
  ]
}

output "ecs_exec_log_group_name" {
  description = "ECS Exec CloudWatch log group name when ECS Exec is enabled."
  value       = var.enable_execute_command ? aws_cloudwatch_log_group.exec[0].name : null
}
