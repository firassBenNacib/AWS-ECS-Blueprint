output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ECS service ARN."
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "Latest ECS task definition ARN."
  value       = aws_ecs_task_definition.this.arn
}

output "execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN."
  value       = aws_iam_role.task.arn
}

output "deployment_alarm_names" {
  description = "CloudWatch alarms attached to ECS deployment rollback."
  value = length(aws_cloudwatch_metric_alarm.deploy_5xx) > 0 ? [
    aws_cloudwatch_metric_alarm.deploy_5xx[0].alarm_name,
    aws_cloudwatch_metric_alarm.deploy_unhealthy_hosts[0].alarm_name
  ] : []
}
