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
| cluster_arn | ECS cluster ARN hosting the service. | `string` | n/a | yes |
| cluster_name | ECS cluster name hosting the service. | `string` | n/a | yes |
| container_image | Digest-pinned container image URI. | `string` | n/a | yes |
| container_name | Primary container name used in the ECS task definition. | `string` | n/a | yes |
| container_port | Primary container listening port. | `number` | n/a | yes |
| execution_role_name | IAM execution role name for ECS tasks. | `string` | n/a | yes |
| log_group_name | CloudWatch log group name. | `string` | n/a | yes |
| private_subnet_ids | Private subnet IDs used by ECS Fargate tasks. | `list(string)` | n/a | yes |
| service_name | ECS service name. | `string` | n/a | yes |
| service_security_group_ids | Security group IDs attached to ECS tasks. | `list(string)` | n/a | yes |
| task_family | ECS task definition family. | `string` | n/a | yes |
| task_role_name | IAM task role name for ECS tasks. | `string` | n/a | yes |
| alb_arn_suffix | ALB ARN suffix used for deployment alarms. Leave null when the service is not behind the ALB. | `string` | `null` | no |
| alb_request_count_scale_in_cooldown_seconds | Autoscaling scale-in cooldown in seconds for ALB request count policy. | `number` | `300` | no |
| alb_request_count_scale_out_cooldown_seconds | Autoscaling scale-out cooldown in seconds for ALB request count policy. | `number` | `60` | no |
| alb_request_count_target_value | Target ALB request count per target for autoscaling. Leave null to disable. | `number` | `null` | no |
| assign_public_ip | Assign a public IP to ECS tasks. | `bool` | `false` | no |
| command | Optional container command override. | `list(string)` | `[]` | no |
| container_user | Optional container runtime user in UID:GID form. Leave null to use the image default user. | `string` | `null` | no |
| cpu_target_value | Target CPU utilization percentage for autoscaling. | `number` | `70` | no |
| deploy_alarm_5xx_threshold | Threshold for ALB target 5xx deployment alarm. | `number` | `10` | no |
| deploy_alarm_eval_periods | Evaluation periods for ECS deployment rollback alarms. | `number` | `2` | no |
| deploy_alarm_unhealthy_hosts_threshold | Threshold for unhealthy ALB targets deployment alarm. | `number` | `1` | no |
| desired_count | Desired ECS task count. | `number` | `1` | no |
| drop_capabilities | Linux capabilities to drop from the container runtime. | `list(string)` | <pre>[<br/>  "ALL"<br/>]</pre> | no |
| enable_deploy_alarms | Whether to create ALB-backed ECS deployment rollback alarms for this service. | `bool` | `false` | no |
| enable_execute_command | Enable ECS Exec for this service. | `bool` | `false` | no |
| enable_load_balancer | Whether to attach this ECS service to an ALB target group. | `bool` | `false` | no |
| entrypoint | Optional container entrypoint override. | `list(string)` | `[]` | no |
| environment | Plaintext environment variables passed to the container. | `map(string)` | `{}` | no |
| exec_kms_key_arn | KMS key ARN used to encrypt ECS Exec sessions. | `string` | `null` | no |
| exec_log_group_name | CloudWatch log group name used for ECS Exec audit logs. | `string` | `null` | no |
| exec_log_retention_days | CloudWatch log retention in days for ECS Exec logs. | `number` | `365` | no |
| health_check_command | Optional container health check command in ECS format, for example ["CMD-SHELL", "wget ... \|\| exit 1"]. | `list(string)` | `[]` | no |
| health_check_grace_period_seconds | ECS service health-check grace period in seconds. | `number` | `60` | no |
| health_check_interval_seconds | Container health check interval in seconds. | `number` | `30` | no |
| health_check_retries | Container health check retry count. | `number` | `3` | no |
| health_check_start_period_seconds | Container health check start period in seconds. | `number` | `15` | no |
| health_check_timeout_seconds | Container health check timeout in seconds. | `number` | `5` | no |
| load_balancer_target_group_arn | Optional ALB target group ARN used for public service registration. | `string` | `null` | no |
| log_kms_key_id | Optional KMS key ARN for the service log group. | `string` | `null` | no |
| log_retention_days | CloudWatch log retention days for service logs. | `number` | `30` | no |
| max_count | Maximum ECS task count for autoscaling. | `number` | `2` | no |
| memory_target_value | Target memory utilization percentage for autoscaling. | `number` | `75` | no |
| min_count | Minimum ECS task count for autoscaling. | `number` | `1` | no |
| mount_points | Optional container mount points backed by task volumes. | <pre>list(object({<br/>    source_volume  = string<br/>    container_path = string<br/>    read_only      = optional(bool)<br/>  }))</pre> | `[]` | no |
| readonly_root_fs | Run the container with a read-only root filesystem. | `bool` | `true` | no |
| scale_in_cooldown_seconds | Autoscaling scale-in cooldown in seconds. | `number` | `60` | no |
| scale_out_cooldown_seconds | Autoscaling scale-out cooldown in seconds. | `number` | `60` | no |
| secret_arns | Map of container environment variable names to Secrets Manager/SSM ARNs. | `map(string)` | `{}` | no |
| secret_kms_key_arns | Optional KMS key ARNs required to decrypt referenced secrets. | `list(string)` | `[]` | no |
| service_discovery_registry_arn | Optional Cloud Map service ARN used for service discovery registration. | `string` | `null` | no |
| target_group_arn_suffix | Target group ARN suffix used for deployment alarms. Leave null when the service is not behind the ALB. | `string` | `null` | no |
| task_cpu | Fargate task CPU units. | `number` | `512` | no |
| task_memory | Fargate task memory in MiB. | `number` | `1024` | no |
| task_role_policy_json | Optional inline IAM policy JSON attached to the ECS task role. | `string` | `null` | no |
| task_volumes | Optional task-scoped ephemeral volumes. | <pre>list(object({<br/>    name = string<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| deployment_alarm_names | CloudWatch alarms attached to ECS deployment rollback. |
| execution_role_arn | ECS task execution role ARN. |
| service_arn | ECS service ARN. |
| service_name | ECS service name. |
| task_definition_arn | Latest ECS task definition ARN. |
| task_role_arn | ECS task role ARN. |
<!-- END_TF_DOCS -->
