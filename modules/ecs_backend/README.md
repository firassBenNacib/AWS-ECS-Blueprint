# ecs_backend

Reusable Terraform module for ECS Fargate services, task definitions, autoscaling, and runtime logging.

## Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0, < 2.0.0 |
| aws | >= 6.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.alb_request_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.deploy_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.deploy_unhealthy_hosts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.execution_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_exec_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.execution_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.execution_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb_arn_suffix | ALB ARN suffix for CloudWatch metrics dimensions. | `string` | n/a | yes |
| container_image | Container image URI for backend service | `string` | n/a | yes |
| private_subnet_ids | Private subnet IDs used by ECS Fargate tasks | `list(string)` | n/a | yes |
| service_security_group_id | Security group ID attached to ECS service tasks | `string` | n/a | yes |
| target_group_arn | ALB target group ARN for ECS service registration | `string` | n/a | yes |
| target_group_arn_suffix | ALB target group ARN suffix for CloudWatch metrics dimensions. | `string` | n/a | yes |
| alb_request_count_scale_in_cooldown_seconds | Scale-in cooldown (seconds) for ALB request count ECS autoscaling | `number` | `300` | no |
| alb_request_count_scale_out_cooldown_seconds | Scale-out cooldown (seconds) for ALB request count ECS autoscaling | `number` | `60` | no |
| alb_request_count_target_value | Target ALB request count per target for autoscaling. Leave null to disable Step Scaling. | `number` | `null` | no |
| cluster_name | ECS cluster name base | `string` | `"app-backend-cluster"` | no |
| container_name | Container name used in ECS task definition | `string` | `"backend"` | no |
| container_port | Container listening port | `number` | `8088` | no |
| container_user | Container runtime user in UID:GID form. | `string` | `"10001:10001"` | no |
| cpu_target_value | Target CPU utilization for ECS service autoscaling | `number` | `70` | no |
| deploy_alarm_5xx_threshold | Threshold for ALB target 5xx deployment alarm. | `number` | `10` | no |
| deploy_alarm_eval_periods | Evaluation periods for ECS deployment rollback alarms. | `number` | `2` | no |
| deploy_alarm_unhealthy_hosts_threshold | Threshold for ALB unhealthy hosts deployment alarm. | `number` | `1` | no |
| desired_count | Desired ECS task count | `number` | `2` | no |
| drop_capabilities | Linux capabilities to drop from container runtime. | `list(string)` | <pre>[<br/>  "ALL"<br/>]</pre> | no |
| enable_environment_suffix | Suffix ECS resource names with environment | `bool` | `false` | no |
| enable_execute_command | Enable ECS Exec for break-glass task access. | `bool` | `false` | no |
| environment | Plaintext environment variables passed to container | `map(string)` | `{}` | no |
| environment_name_override | Optional explicit environment name used for ECS resource naming. Leave null to derive it from the current Terraform context. | `string` | `null` | no |
| exec_kms_key_arn | KMS key ARN for ECS Exec session encryption. | `string` | `null` | no |
| exec_log_group_name | CloudWatch log group base name for ECS Exec audit logs. | `string` | `"app-backend-ecs-exec"` | no |
| exec_log_retention_days | CloudWatch log retention for ECS Exec audit logs. | `number` | `365` | no |
| execution_role_name | IAM execution role name base for ECS tasks | `string` | `"ecs-backend-execution-role"` | no |
| health_check_grace_period_seconds | ECS service health-check grace period in seconds. | `number` | `60` | no |
| log_group_name | CloudWatch log group name base | `string` | `"app-backend"` | no |
| log_kms_key_id | Optional KMS key ARN for ECS backend CloudWatch logs | `string` | `null` | no |
| log_retention_days | CloudWatch log retention for ECS backend | `number` | `30` | no |
| max_count | Maximum ECS task count for autoscaling | `number` | `4` | no |
| memory_target_value | Target memory utilization for ECS service autoscaling | `number` | `75` | no |
| min_count | Minimum ECS task count for autoscaling | `number` | `2` | no |
| readonly_root_fs | Run container with read-only root filesystem. | `bool` | `true` | no |
| scale_in_cooldown_seconds | Autoscaling scale-in cooldown in seconds | `number` | `60` | no |
| scale_out_cooldown_seconds | Autoscaling scale-out cooldown in seconds | `number` | `60` | no |
| secret_arns | Map of container environment variable names to Secrets Manager/SSM ARNs | `map(string)` | `{}` | no |
| secret_kms_key_arns | Optional list of KMS key ARNs used to decrypt referenced secrets | `list(string)` | `[]` | no |
| service_name | ECS service name base | `string` | `"app-backend-service"` | no |
| task_cpu | Fargate task CPU units | `number` | `512` | no |
| task_family | ECS task definition family base | `string` | `"app-backend-task"` | no |
| task_memory | Fargate task memory in MiB | `number` | `1024` | no |
| task_role_name | IAM task role name base for ECS tasks | `string` | `"ecs-backend-task-role"` | no |
| task_role_policy_json | Optional inline IAM policy JSON document attached to the ECS task role | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_arn | ECS cluster ARN |
| cluster_name | ECS cluster name |
| deployment_alarm_names | CloudWatch alarms attached to ECS deployment rollback. |
| ecs_exec_log_group_name | ECS Exec CloudWatch log group name when ECS Exec is enabled. |
| execution_role_arn | ECS task execution role ARN |
| service_arn | ECS service ARN |
| service_name | ECS service name |
| service_security_group_id | Security group ID attached to ECS tasks |
| task_definition_arn | Latest ECS task definition ARN |
| task_role_arn | ECS task role ARN |
<!-- END_TF_DOCS -->
