output "alarm_names" {
  value = {
    alb_target_5xx             = try(aws_cloudwatch_metric_alarm.alb_target_5xx[0].alarm_name, null)
    ecs_running_task_count_low = try(aws_cloudwatch_metric_alarm.ecs_running_task_count_low[0].alarm_name, null)
    rds_cpu_high               = try(aws_cloudwatch_metric_alarm.rds_cpu_high[0].alarm_name, null)
    cloudfront_5xx_rate_high   = try(aws_cloudwatch_metric_alarm.cloudfront_5xx_rate_high[0].alarm_name, null)
  }
}
