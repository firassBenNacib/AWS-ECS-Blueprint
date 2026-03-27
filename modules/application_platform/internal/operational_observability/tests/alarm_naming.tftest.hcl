mock_provider "aws" {}

variables {
  enabled                    = true
  name_prefix                = "example-app-nonprod"
  notifications_topic_arn    = null
  alb_arn_suffix             = "app/example/1234567890"
  target_group_arn_suffix    = "targetgroup/example/abcdef123456"
  ecs_cluster_name           = "example-app-nonprod"
  ecs_service_name           = "gateway"
  rds_instance_identifier    = "example-app-nonprod-rds"
  cloudfront_distribution_id = "E1234567890ABC"
}

run "alarm_names_follow_the_expected_prefix" {
  command = plan

  assert {
    condition     = output.alarm_names.alb_target_5xx == "example-app-nonprod-alb-target-5xx"
    error_message = "The ALB 5xx alarm should use the configured name prefix."
  }

  assert {
    condition     = output.alarm_names.ecs_running_task_count_low == "example-app-nonprod-ecs-running-task-count-low"
    error_message = "The ECS running task alarm should use the configured name prefix."
  }

  assert {
    condition     = output.alarm_names.rds_cpu_high == "example-app-nonprod-rds-cpu-high"
    error_message = "The RDS CPU alarm should use the configured name prefix."
  }

  assert {
    condition     = output.alarm_names.cloudfront_5xx_rate_high == "example-app-nonprod-cloudfront-5xx-rate-high"
    error_message = "The CloudFront 5xx alarm should use the configured name prefix."
  }
}

run "disabled_operational_alarms_return_null_outputs" {
  command = plan

  variables {
    enabled = false
  }

  assert {
    condition     = output.alarm_names.alb_target_5xx == null && output.alarm_names.ecs_running_task_count_low == null && output.alarm_names.rds_cpu_high == null && output.alarm_names.cloudfront_5xx_rate_high == null
    error_message = "Disabled operational alarms should not publish concrete alarm names."
  }
}
