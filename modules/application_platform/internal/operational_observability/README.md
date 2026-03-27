<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.alb_target_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cloudfront_5xx_rate_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_running_task_count_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb_arn_suffix | ALB ARN suffix used by ApplicationELB metrics. | `string` | n/a | yes |
| cloudfront_distribution_id | CloudFront distribution ID used by distribution metrics. | `string` | n/a | yes |
| ecs_cluster_name | ECS cluster name used by RunningTaskCount metrics. | `string` | n/a | yes |
| ecs_service_name | Public ECS service name used by RunningTaskCount metrics. | `string` | n/a | yes |
| enabled | Whether workload-level operational alarms should be created. | `bool` | n/a | yes |
| name_prefix | Prefix used when naming CloudWatch alarms. | `string` | n/a | yes |
| rds_instance_identifier | RDS instance identifier used by DB metrics. | `string` | n/a | yes |
| target_group_arn_suffix | Target group ARN suffix used by ApplicationELB metrics. | `string` | n/a | yes |
| alb_target_5xx_evaluation_periods | Evaluation periods for backend ALB target 5xx count alarms. | `number` | `2` | no |
| alb_target_5xx_threshold | Threshold for backend ALB target 5xx count alarms. | `number` | `10` | no |
| cloudfront_5xx_evaluation_periods | Evaluation periods for the CloudFront 5xx error rate alarm. | `number` | `2` | no |
| cloudfront_5xx_rate_threshold | CloudFront 5xx error rate threshold for the frontend distribution alarm. | `number` | `5` | no |
| ecs_running_task_evaluation_periods | Evaluation periods for the ECS running task count alarm. | `number` | `2` | no |
| ecs_running_task_min_threshold | Minimum running task count threshold before the ECS service alarm fires. | `number` | `1` | no |
| notifications_topic_arn | Optional SNS topic ARN subscribed to CloudWatch alarm state changes. | `string` | `null` | no |
| rds_cpu_evaluation_periods | Evaluation periods for the RDS CPU alarm. | `number` | `3` | no |
| rds_cpu_threshold | Average RDS CPU utilization threshold for the high CPU alarm. | `number` | `80` | no |

## Outputs

| Name | Description |
|------|-------------|
| alarm_names | n/a |
<!-- END_TF_DOCS -->