locals {
  operational_alarms_enabled = var.enabled
  alarm_actions              = var.notifications_topic_arn != null ? [var.notifications_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  count = local.operational_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-target-5xx"
  alarm_description   = "Alert when backend ALB target 5xx responses breach the configured threshold."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = var.alb_target_5xx_evaluation_periods
  threshold           = var.alb_target_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_task_count_low" {
  count = local.operational_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-running-task-count-low"
  alarm_description   = "Alert when the public ECS service drops below the expected running task count."
  namespace           = "AWS/ECS"
  metric_name         = "RunningTaskCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = var.ecs_running_task_evaluation_periods
  threshold           = var.ecs_running_task_min_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = local.operational_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "Alert when workload RDS CPU utilization remains above the configured threshold."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = var.rds_cpu_evaluation_periods
  threshold           = var.rds_cpu_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_rate_high" {
  count = local.operational_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-cloudfront-5xx-rate-high"
  alarm_description   = "Alert when the frontend CloudFront distribution 5xx error rate breaches the configured threshold."
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = var.cloudfront_5xx_evaluation_periods
  threshold           = var.cloudfront_5xx_rate_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }
}
