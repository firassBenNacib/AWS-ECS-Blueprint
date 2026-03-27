# application_platform

Shared application deployment used by the `prod-app` and `nonprod-app` deployment roots.

## Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0, < 2.0.0 |
| archive | >= 2.4, < 3.0 |
| aws | >= 6.0, < 7.0 |
| external | >= 2.3, < 3.0 |
| null | >= 3.2, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0, < 7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| access_log_storage | ./internal/access_log_storage | n/a |
| app_data | ./internal/app_data | n/a |
| app_runtime | ./internal/app_runtime | n/a |
| backend_edge | ./internal/backend_edge | n/a |
| deployment_contract | ./internal/deployment_contract | n/a |
| edge_contract | ./internal/edge_contract | n/a |
| frontend_edge | ./internal/frontend_edge | n/a |
| frontend_origin_access | ./internal/frontend_origin_access | n/a |
| frontend_storage | ./internal/frontend_storage | n/a |
| networking | ./internal/networking | n/a |
| operational_observability | ./internal/operational_observability | n/a |
| platform_core | ./internal/platform_core | n/a |
| platform_governance | ./internal/platform_governance | n/a |
| policy_assembly | ./internal/policy_assembly | n/a |

## Resources

| Name | Type |
|------|------|

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acm_cert_frontend | ACM certificate ARN for frontend CloudFront distribution (must be us-east-1) | `string` | n/a | yes |
| bucket_name | Name of the frontend S3 bucket | `string` | n/a | yes |
| environment_domain | Base domain used for environment-derived aliases (for example: example.com). | `string` | n/a | yes |
| project_name | Required project name applied to resource names, tags, and internal DNS defaults. | `string` | n/a | yes |
| rds_username | RDS master username | `string` | n/a | yes |
| alb_access_logs_prefix | S3 prefix for ALB access logs | `string` | `"alb/"` | no |
| alb_certificate_arn | Regional ACM certificate ARN for the ALB HTTPS listener (can be imported from Let's Encrypt) | `string` | `null` | no |
| alb_deletion_protection | Enable ALB deletion protection (required in this production-only configuration) | `bool` | `true` | no |
| alb_health_check_healthy_threshold | ALB target group healthy threshold count | `number` | `2` | no |
| alb_health_check_interval_seconds | ALB target group health check interval (seconds) | `number` | `30` | no |
| alb_health_check_matcher | ALB target group health check matcher | `string` | `"200-399"` | no |
| alb_health_check_timeout_seconds | ALB target group health check timeout (seconds) | `number` | `5` | no |
| alb_health_check_unhealthy_threshold | ALB target group unhealthy threshold count | `number` | `3` | no |
| alb_idle_timeout | ALB idle timeout in seconds | `number` | `60` | no |
| alb_listener_port | Backend ALB primary listener port used by CloudFront origin traffic | `number` | `443` | no |
| alb_name | Backend ALB name base | `string` | `"app-backend-alb"` | no |
| alb_ssl_policy | SSL policy for the ALB HTTPS listener | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| alb_target_group_name | Backend ALB target group name base | `string` | `"app-backend-tg"` | no |
| alb_web_acl_arn | Optional WAFv2 Web ACL ARN for backend ALB (regional) | `string` | `null` | no |
| allowed_image_registries | Optional list of approved container image URI prefixes (for example: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/repo). When empty, the managed backend ECR repository prefix is enforced. | `list(string)` | `[]` | no |
| app_runtime_mode | Application runtime topology. single_backend keeps the existing one-service backend path; gateway_microservices exposes one public ECS service behind the ALB and keeps the remaining ECS services private behind service discovery. | `string` | `"single_backend"` | no |
| availability_zones | List of availability zones | `list(string)` | `[]` | no |
| aws_backup_completion_window_minutes | Completion window in minutes for the AWS Backup rule. | `number` | `180` | no |
| aws_backup_copy_retention_days | Retention period in days for copied DR-region recovery points. | `number` | `35` | no |
| aws_backup_cross_region_copy_enabled | When true, copy AWS Backup recovery points to a DR-region backup vault. | `bool` | `true` | no |
| aws_backup_retention_days | Retention period in days for primary-region recovery points. | `number` | `35` | no |
| aws_backup_schedule_expression | Cron expression for the AWS Backup RDS backup rule. | `string` | `"cron(0 5 * * ? *)"` | no |
| aws_backup_start_window_minutes | Start window in minutes for the AWS Backup rule. | `number` | `60` | no |
| aws_backup_vault_name | Optional AWS Backup vault base name. When null, an environment-prefixed default is used. | `string` | `null` | no |
| aws_region | AWS region for primary resources. | `string` | `"eu-west-1"` | no |
| backend_alb_request_count_scale_in_cooldown_seconds | Scale-in cooldown (seconds) for ALB request count ECS autoscaling | `number` | `300` | no |
| backend_alb_request_count_scale_out_cooldown_seconds | Scale-out cooldown (seconds) for ALB request count ECS autoscaling | `number` | `60` | no |
| backend_alb_request_count_target_value | Target ALB request count per target for autoscaling. Leave null to disable Step Scaling. | `number` | `null` | no |
| backend_cache_policy_id | CloudFront cache policy ID for backend distribution | `string` | `"4135ea2d-6df8-44a3-9df3-4b5a84be39ad"` | no |
| backend_cluster_name | ECS cluster name base | `string` | `"app-backend-cluster"` | no |
| backend_container_image | Container image URI for backend ECS service. Production requires digest-pinned form (for example: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/app@sha256:<digest>). | `string` | `null` | no |
| backend_container_name | Container name used by ECS task definition and service load balancer mapping | `string` | `"backend"` | no |
| backend_container_port | Backend container listening port | `number` | `8088` | no |
| backend_container_user | Container runtime user in UID:GID form. | `string` | `"10001:10001"` | no |
| backend_cpu_target_value | Target ECS service CPU utilization percentage for autoscaling | `number` | `70` | no |
| backend_deploy_alarm_5xx_threshold | Alarm threshold for ALB target 5xx errors during ECS deployments. | `number` | `10` | no |
| backend_deploy_alarm_eval_periods | Number of evaluation periods for ECS deployment rollback alarms. | `number` | `2` | no |
| backend_deploy_alarm_unhealthy_hosts_threshold | Alarm threshold for unhealthy ALB targets during ECS deployments. | `number` | `1` | no |
| backend_desired_count | Desired ECS task count | `number` | `2` | no |
| backend_drop_linux_capabilities | Linux capabilities to drop in backend container runtime. | `list(string)` | <pre>[<br/>  "ALL"<br/>]</pre> | no |
| backend_ecr_kms_key_arn | Optional KMS key ARN for ECR repository encryption. When null, ECR uses the default AWS-managed key. | `string` | `null` | no |
| backend_ecr_lifecycle_max_images | Maximum number of backend container images to retain in ECR. | `number` | `30` | no |
| backend_ecr_repository_name | Backend ECR repository base name. | `string` | `"app-backend"` | no |
| backend_env | Additional plaintext environment variables for backend container | `map(string)` | `{}` | no |
| backend_execution_role_name | ECS task execution IAM role name base | `string` | `"ecs-backend-execution-role"` | no |
| backend_healthcheck_grace_period_seconds | ECS service health-check grace period in seconds. | `number` | `60` | no |
| backend_healthcheck_path | ALB health check path for backend service | `string` | `"/health"` | no |
| backend_ingress_mode | Backend ingress architecture. vpc_origin_alb keeps the ALB private behind a CloudFront VPC origin. public_alb_restricted uses a public ALB restricted to CloudFront origin-facing infrastructure. | `string` | `"vpc_origin_alb"` | no |
| backend_log_group_name | CloudWatch log group name base for backend ECS logs | `string` | `"app-backend"` | no |
| backend_log_kms_key_id | Optional KMS key ARN for backend ECS CloudWatch log group encryption. | `string` | `null` | no |
| backend_log_retention_days | CloudWatch log retention days for backend ECS logs | `number` | `30` | no |
| backend_max_count | Maximum ECS task count for autoscaling | `number` | `4` | no |
| backend_memory_target_value | Target ECS service memory utilization percentage for autoscaling | `number` | `75` | no |
| backend_min_count | Minimum ECS task count for autoscaling | `number` | `2` | no |
| backend_origin_protocol_policy | CloudFront-to-backend origin protocol policy for the primary backend origin. Only HTTPS is supported. | `string` | `"https-only"` | no |
| backend_origin_request_policy_id | CloudFront origin request policy ID for backend distribution | `string` | `"b689b0a8-53d0-40ab-baf2-68738e2966ac"` | no |
| backend_rds_secret_env_var_name | Environment variable name used to inject the RDS managed secret into backend ECS tasks | `string` | `"DB_CREDENTIALS"` | no |
| backend_readonly_root_filesystem | Run backend container with a read-only root filesystem. | `bool` | `true` | no |
| backend_scale_in_cooldown_seconds | Scale-in cooldown (seconds) for ECS autoscaling | `number` | `60` | no |
| backend_scale_out_cooldown_seconds | Scale-out cooldown (seconds) for ECS autoscaling | `number` | `60` | no |
| backend_secret_arns | Map of environment variable names to Secrets Manager/SSM secret ARNs for backend container | `map(string)` | `{}` | no |
| backend_secret_kms_key_arns | Optional list of KMS key ARNs required to decrypt backend secrets | `list(string)` | `[]` | no |
| backend_service_name | ECS service name base | `string` | `"app-backend-service"` | no |
| backend_task_cpu | Fargate task CPU units | `number` | `512` | no |
| backend_task_family | ECS task definition family base | `string` | `"app-backend-task"` | no |
| backend_task_memory | Fargate task memory in MiB | `number` | `1024` | no |
| backend_task_role_name | ECS task IAM role name base | `string` | `"ecs-backend-task-role"` | no |
| backend_task_role_policy_json | Optional inline IAM policy JSON attached to backend ECS task role | `string` | `null` | no |
| backend_viewer_protocol_policy | Viewer protocol policy for backend CloudFront distribution | `string` | `"redirect-to-https"` | no |
| backend_web_acl_arn | Optional WAFv2 Web ACL ARN for backend CloudFront distribution | `string` | `null` | no |
| budget_alert_email_addresses | Email addresses subscribed to AWS Budgets alerts. | `list(string)` | `[]` | no |
| budget_alert_threshold_percentages | Percentage thresholds that trigger ACTUAL spend AWS Budgets notifications. | `list(number)` | <pre>[<br/>  80,<br/>  100<br/>]</pre> | no |
| budget_alert_topic_arns | SNS topic ARNs subscribed to AWS Budgets alerts. | `list(string)` | `[]` | no |
| budget_cloudfront_monthly_limit | Optional monthly budget limit for Amazon CloudFront. | `number` | `null` | no |
| budget_rds_monthly_limit | Optional monthly budget limit for Amazon Relational Database Service. | `number` | `null` | no |
| budget_total_monthly_limit | Optional total monthly budget limit. | `number` | `null` | no |
| budget_vpc_monthly_limit | Optional monthly budget limit for Amazon Virtual Private Cloud charges, including NAT-related spend. | `number` | `null` | no |
| cloudfront_logs_abort_incomplete_multipart_upload_days | Abort incomplete multipart uploads in CloudFront logs bucket after this many days | `number` | `7` | no |
| cloudfront_logs_bucket_name | S3 bucket name used to store CloudFront access logs when enable_cloudfront_access_logs=true | `string` | `""` | no |
| cloudfront_logs_expiration_days | Expire CloudFront access log objects after this many days | `number` | `90` | no |
| cloudfront_logs_prefix | Prefix for CloudFront access logs objects | `string` | `"cloudfront/"` | no |
| cloudtrail_data_event_resources | CloudTrail data-event resource ARNs (for example S3 object data selectors like arn:aws:s3:::bucket-name/). | `list(string)` | `[]` | no |
| create_backend_ecr_repository | Create a managed ECR repository for backend images with immutable tags and scan-on-push. | `bool` | `true` | no |
| destroy_mode_enabled | Relax deletion protections and enable force-destroy semantics for repeatable teardown. | `bool` | `false` | no |
| dr_cloudfront_logs_bucket_name | Optional DR replica bucket name for CloudFront logs. When empty, an environment-aware default name is generated. | `string` | `""` | no |
| dr_frontend_bucket_name | Optional DR replica bucket name for frontend content. When empty, an environment-aware default name is generated. | `string` | `""` | no |
| dr_region | AWS region for disaster-recovery replicas (S3 replication targets). | `string` | `"us-west-2"` | no |
| dr_s3_kms_key_id | Optional KMS key ARN for DR-region S3 replica encryption. When null, a managed key is created in the DR region. | `string` | `null` | no |
| ecs_exec_log_group_name | CloudWatch log group base name for ECS Exec audit logs. | `string` | `"app-backend-ecs-exec"` | no |
| ecs_exec_log_retention_days | CloudWatch log retention days for ECS Exec audit logs. | `number` | `365` | no |
| ecs_services | Generic ECS service map used in gateway_microservices mode. | <pre>map(object({<br/>    image                             = string<br/>    container_port                    = number<br/>    container_name                    = optional(string)<br/>    public                            = optional(bool)<br/>    desired_count                     = optional(number)<br/>    min_count                         = optional(number)<br/>    max_count                         = optional(number)<br/>    cpu                               = optional(number)<br/>    memory                            = optional(number)<br/>    health_check_grace_period_seconds = optional(number)<br/>    health_check_path                 = optional(string)<br/>    container_user                    = optional(string)<br/>    readonly_root_fs                  = optional(bool)<br/>    drop_capabilities                 = optional(list(string))<br/>    env                               = optional(map(string))<br/>    secret_arns                       = optional(map(string))<br/>    secret_kms_key_arns               = optional(list(string))<br/>    task_role_policy_json             = optional(string)<br/>    log_group_name                    = optional(string)<br/>    log_retention_days                = optional(number)<br/>    log_kms_key_id                    = optional(string)<br/>    entrypoint                        = optional(list(string))<br/>    command                           = optional(list(string))<br/>    mount_points = optional(list(object({<br/>      source_volume  = string<br/>      container_path = string<br/>      read_only      = optional(bool)<br/>    })))<br/>    task_volumes = optional(list(object({<br/>      name = string<br/>    })))<br/>    health_check_command              = optional(list(string))<br/>    health_check_interval_seconds     = optional(number)<br/>    health_check_timeout_seconds      = optional(number)<br/>    health_check_retries              = optional(number)<br/>    health_check_start_period_seconds = optional(number)<br/>    assign_public_ip                  = optional(bool)<br/>    enable_service_discovery          = optional(bool)<br/>    discovery_name                    = optional(string)<br/>    extra_egress = optional(list(object({<br/>      description = string<br/>      protocol    = string<br/>      from_port   = number<br/>      to_port     = number<br/>      cidr_blocks = list(string)<br/>    })))<br/>  }))</pre> | `{}` | no |
| enable_account_security_controls | When true, this root owns account-level security controls in addition to workload infrastructure. | `bool` | `true` | no |
| enable_aws_backup | Enable AWS Backup plan/selection for the primary RDS instance. | `bool` | `true` | no |
| enable_aws_config | Enable AWS Config recorder and delivery channel inside the account-level security baseline. | `bool` | `true` | no |
| enable_budget_alerts | Whether optional AWS Budgets alerts should be created for monthly spend visibility. | `bool` | `false` | no |
| enable_cloudfront_access_logs | Enable CloudFront standard access logs for frontend and backend distributions | `bool` | `true` | no |
| enable_cloudfront_logs_lifecycle | Enable lifecycle expiration for CloudFront access logs bucket when logs are enabled | `bool` | `true` | no |
| enable_cloudtrail_data_events | Enable CloudTrail data event selectors for high-value resource telemetry. | `bool` | `false` | no |
| enable_cost_optimized_dev_tier | Enable a lower-cost dev tier profile that reduces account-level controls, forces private-app NAT to disabled, and uses single-AZ RDS. | `bool` | `false` | no |
| enable_ecs_exec | Enable ECS Exec for break-glass debugging access. | `bool` | `false` | no |
| enable_ecs_exec_audit_alerts | When true, route ECS Exec shell access events to the security notifications topic in production. | `bool` | `true` | no |
| enable_environment_suffix | Append the effective environment name to shared resource names. Keep enabled for dedicated per-environment roots. | `bool` | `true` | no |
| enable_inspector | Enable Amazon Inspector for account-level vulnerability scanning. | `bool` | `true` | no |
| enable_managed_waf | Create and attach default managed-rule WAF ACLs when explicit ARNs are not provided | `bool` | `true` | no |
| enable_operational_alarms | When true, create workload-level CloudWatch alarms for ALB 5xxs, public ECS service health, RDS CPU, and CloudFront 5xx rate. | `bool` | `false` | no |
| enable_origin_auth_header | Enable CloudFront origin custom-header authentication for backend origin protection | `bool` | `true` | no |
| enable_rds_iam_auth | Enable IAM database authentication for RDS MySQL | `bool` | `true` | no |
| enable_rds_master_user_password_rotation | Enable automatic rotation for the RDS-managed master user password. | `bool` | `true` | no |
| enable_s3_access_logging | Enable S3 server access logging for primary S3 buckets | `bool` | `true` | no |
| enable_s3_lifecycle | Enable lifecycle rules on the frontend S3 bucket | `bool` | `true` | no |
| enable_security_baseline | Enable account-level production security baseline controls (CloudTrail, Config, GuardDuty, Security Hub, Access Analyzer). | `bool` | `true` | no |
| environment_name_override | Optional explicit environment name used for naming and DNS derivation. Leave null to derive it from the current Terraform context. | `string` | `null` | no |
| frontend_cache_policy_id | CloudFront cache policy ID for frontend distribution | `string` | `"658327ea-f89d-4fab-a63d-7e88639e58f6"` | no |
| frontend_geo_locations | ISO 3166-1 alpha-2 country codes used when frontend_geo_restriction_type is whitelist or blacklist. | `list(string)` | `[]` | no |
| frontend_geo_restriction_type | Frontend CloudFront geo restriction mode: none, whitelist, or blacklist. | `string` | `"none"` | no |
| frontend_price_class | CloudFront price class for frontend distribution | `string` | `"PriceClass_100"` | no |
| frontend_runtime_mode | Frontend runtime topology. s3 keeps the current S3+CloudFront static model; ecs targets the internal ALB/ECS frontend origin. | `string` | `"s3"` | no |
| frontend_viewer_protocol_policy | Viewer protocol policy for frontend CloudFront distribution | `string` | `"https-only"` | no |
| frontend_web_acl_arn | Optional WAFv2 Web ACL ARN for frontend CloudFront distribution | `string` | `null` | no |
| interface_endpoint_services | AWS service short names used to create Interface VPC Endpoints for private Fargate runtime dependencies. | `list(string)` | <pre>[<br/>  "ecr.api",<br/>  "ecr.dkr",<br/>  "logs",<br/>  "sts",<br/>  "secretsmanager",<br/>  "kms"<br/>]</pre> | no |
| live_validation_dns_label | Stable DNS label used for live-validation public aliases (for example: lv-prod). Required when live_validation_mode=true. | `string` | `null` | no |
| live_validation_mode | When true, the deployment is being created only for isolated live-validation runs and must use an lv-* environment name. | `bool` | `false` | no |
| lockdown_default_security_group | When true, remove all ingress/egress rules from the default security group of the dedicated VPC. | `bool` | `true` | no |
| operational_alarm_alb_target_5xx_threshold | Threshold for backend ALB target 5xx count operational alarms. | `number` | `10` | no |
| operational_alarm_cloudfront_5xx_rate_threshold | CloudFront 5xx error rate threshold for the frontend operational alarm. | `number` | `5` | no |
| operational_alarm_ecs_running_task_min_threshold | Minimum running task count threshold before the public ECS service operational alarm fires. | `number` | `1` | no |
| operational_alarm_rds_cpu_threshold | Average RDS CPU utilization threshold for the workload operational alarm. | `number` | `80` | no |
| operational_alarm_topic_arn | Optional SNS topic ARN receiving workload operational alarms. When null, the module reuses the security findings topic if one exists. | `string` | `null` | no |
| origin_auth_header_name | Primary custom header name used for backend origin authentication | `string` | `"X-Origin-Verify"` | no |
| origin_auth_header_ssm_parameter_name | SSM SecureString parameter name containing the primary origin-auth header value. | `string` | `""` | no |
| origin_auth_previous_header_name | Secondary custom header name used during origin auth secret rotation | `string` | `"X-Origin-Verify-Prev"` | no |
| origin_auth_previous_header_ssm_parameter_name | Optional SSM SecureString parameter name containing the previous origin-auth header value for safe rotation windows. | `string` | `""` | no |
| private_app_nat_mode | Private app subnet internet egress mode: required (all subnets via NAT), canary (single-subnet NAT route), or disabled (no NAT default route). | `string` | `"required"` | no |
| private_app_subnet_cidrs | CIDR blocks for private application subnets (backend service tasks) | `list(string)` | `[]` | no |
| private_db_subnet_cidrs | CIDR blocks for private database subnets | `list(string)` | `[]` | no |
| public_app_subnet_cidrs | CIDR blocks for public edge subnets (ALB/NAT gateways) | `list(string)` | `[]` | no |
| rds_allocated_storage | RDS allocated storage in GB | `number` | `20` | no |
| rds_backup_retention_period | RDS backup retention period in days | `number` | `14` | no |
| rds_db_name | Database name | `string` | `"app"` | no |
| rds_deletion_protection | Enable RDS deletion protection during normal operation. | `bool` | `true` | no |
| rds_enable_performance_insights | Enable RDS Performance Insights when the selected instance class supports it. | `bool` | `false` | no |
| rds_enabled_cloudwatch_logs_exports | RDS MySQL log types exported to CloudWatch Logs | `list(string)` | <pre>[<br/>  "audit",<br/>  "error",<br/>  "general",<br/>  "slowquery"<br/>]</pre> | no |
| rds_engine_version | RDS engine version for the workload MySQL instance. | `string` | `"8.0.45"` | no |
| rds_final_snapshot_identifier | Optional final snapshot identifier | `string` | `null` | no |
| rds_identifier | RDS instance identifier | `string` | `"app-rds"` | no |
| rds_instance_class | RDS instance class | `string` | `"db.t4g.micro"` | no |
| rds_master_user_password_rotation_automatically_after_days | Rotation interval in days for the RDS-managed master user password. | `number` | `30` | no |
| rds_master_user_secret_kms_key_id | Optional KMS key ID or ARN for RDS managed master user secret encryption. When null, Secrets Manager uses the default key. | `string` | `null` | no |
| rds_max_allocated_storage | RDS maximum allocated storage in GB for autoscaling. Set to 0 to disable. Defaults to 100 GB to allow online autoscaling. | `number` | `100` | no |
| rds_monitoring_interval_seconds | Enhanced monitoring interval for RDS in seconds (0 disables) | `number` | `60` | no |
| rds_multi_az | Enable Multi-AZ deployment for the workload RDS instance. | `bool` | `true` | no |
| rds_preferred_backup_window | Preferred daily backup window for RDS (UTC). | `string` | `"03:00-04:00"` | no |
| rds_preferred_maintenance_window | Preferred weekly maintenance window for RDS (UTC). | `string` | `"sun:04:30-sun:05:30"` | no |
| rds_skip_final_snapshot_on_destroy | Skip the final RDS snapshot on destroy. destroy_mode_enabled forces this on. | `bool` | `false` | no |
| resource_contract_tags | Additional root-level contract tags merged into provider default tags. | `map(string)` | `{}` | no |
| route53_zone_id | Optional Route 53 public hosted zone ID override. | `string` | `null` | no |
| route53_zone_strategy | How to resolve the public hosted zone when route53_zone_id is not set: explicit, autodiscover, or create. | `string` | `"explicit"` | no |
| s3_access_logs_bucket_name | Optional dedicated S3 bucket name for server access logs. When empty, an environment-aware default name is generated. | `string` | `""` | no |
| s3_force_destroy | Allow destroying non-empty frontend S3 bucket (not recommended for production) | `bool` | `false` | no |
| s3_kms_key_id | Optional KMS key ARN for primary-region S3 encryption. When null, a managed key is created. | `string` | `null` | no |
| s3_lifecycle_abort_incomplete_multipart_upload_days | Abort incomplete multipart uploads in frontend S3 bucket after this many days | `number` | `7` | no |
| s3_lifecycle_expiration_days | Optional expiration age (days) for current frontend S3 objects | `number` | `null` | no |
| s3_lifecycle_noncurrent_expiration_days | Optional expiration age (days) for noncurrent frontend S3 object versions | `number` | `30` | no |
| s3_versioning_enabled | Enable frontend bucket versioning | `bool` | `true` | no |
| security_baseline_enable_object_lock | Enable S3 Object Lock on the security baseline audit-log bucket. | `bool` | `false` | no |
| security_baseline_log_retention_days | Retention in days for account-level security baseline log storage lifecycle. | `number` | `365` | no |
| security_findings_sns_subscriptions | Optional managed-topic subscriptions for security findings notifications. | <pre>list(object({<br/>    protocol = string<br/>    endpoint = string<br/>  }))</pre> | `[]` | no |
| security_findings_sns_topic_arn | Optional existing SNS topic ARN that receives high/critical GuardDuty and Security Hub findings. When null, a managed topic is created. | `string` | `null` | no |
| securityhub_standards_arns | Optional explicit Security Hub standard subscription ARNs. Leave empty to use AWS Foundational + CIS defaults. | `list(string)` | `[]` | no |
| service_discovery_namespace_name | Optional private DNS namespace used for ECS service discovery in gateway_microservices mode. Leave null to derive an environment-specific internal namespace. | `string` | `null` | no |
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| vpc_flow_logs_kms_key_id | Optional KMS key ARN for VPC Flow Logs encryption. When null, flow logs are not KMS-encrypted. | `string` | `null` | no |
| vpc_flow_logs_retention_days | CloudWatch log retention days for VPC Flow Logs. | `number` | `365` | no |
| vpc_name | Name for the VPC | `string` | `"app-vpc"` | no |
| waf_log_retention_days | CloudWatch Logs retention for managed WAF ACL logs | `number` | `365` | no |
| waf_rate_limit_requests_per_5_mins | WAF rate-limit threshold: maximum requests per 5 minutes per source IP before the rule blocks traffic. | `number` | `2000` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_access_logs_bucket_name | Primary-region ALB access logs bucket. |
| alb_access_logs_dr_bucket_name | DR-region ALB access logs bucket. |
| app_runtime_mode | Active application runtime mode. |
| aws_backup_enabled | Whether per-root AWS Backup remains enabled after deployment-contract overrides. |
| backend_alb_arn | Internal backend ALB ARN. |
| backend_alb_dns_name | Backend ALB DNS name used as CloudFront origin. |
| backend_alb_security_group_id | n/a |
| backend_alb_target_group_arn | Backend ALB target group ARN attached to the ECS service. |
| backend_ecr_repository_name | Managed backend ECR repository name when create_backend_ecr_repository=true. |
| backend_ecr_repository_url | Managed backend ECR repository URL when create_backend_ecr_repository=true. |
| backend_ecs_cluster_name | Backend ECS cluster name. |
| backend_ecs_service_name | Backend ECS service name. |
| backend_ecs_task_definition_arn | Backend ECS task definition ARN. |
| backend_effective_desired_count | Effective desired count for the single-backend ECS service after deployment-contract overrides. |
| backend_effective_max_count | Effective maximum count for the single-backend ECS service after deployment-contract overrides. |
| backend_effective_min_count | Effective minimum count for the single-backend ECS service after deployment-contract overrides. |
| backend_service_security_group_id | n/a |
| backup_plan_id | Per-root AWS Backup plan ID. |
| backup_vault_name | Per-root AWS Backup vault name. |
| budget_alerts_enabled | Whether optional AWS Budgets alerts are enabled for this deployment. |
| budget_arns | Budget ARNs keyed by logical budget category. |
| budget_names | Budget names keyed by logical budget category. |
| cloudfront_logs_bucket_name | CloudFront access logs bucket. |
| cloudfront_logs_dr_bucket_name | DR replica bucket for CloudFront logs. |
| cost_optimized_dev_tier_enabled | Whether the cost-optimized dev tier profile is active. |
| db_subnet_ids | n/a |
| ecs_service_names | ECS service names keyed by logical service name in gateway_microservices mode. |
| effective_private_app_nat_mode | Effective private app subnet NAT mode after deployment-contract overrides. |
| frontend_aliases | Frontend DNS aliases managed by the deployment. |
| frontend_bucket_name | Primary frontend content bucket in frontend s3 mode; null in frontend ecs mode. |
| frontend_cert_arn | ACM certificate ARN used by the frontend CloudFront distribution. |
| frontend_cloudfront_distribution_id | Frontend CloudFront distribution ID. |
| frontend_cloudfront_url | n/a |
| frontend_dr_bucket_name | DR replica bucket for frontend content in frontend s3 mode; null in frontend ecs mode. |
| managed_waf_enabled | Whether managed WAF remains enabled after deployment-contract overrides. |
| operational_alarm_names | Workload operational alarm names keyed by alarm purpose. |
| private_app_subnet_ids | Private app subnet IDs used by backend ECS service |
| public_app_subnet_ids | Public edge subnet IDs used by NAT/egress routing. |
| public_service_name | Public ECS service name attached to the backend ALB in gateway_microservices mode. |
| rds_endpoint | n/a |
| rds_instance_arn | RDS instance ARN. |
| rds_instance_id | RDS instance identifier. |
| rds_master_user_secret_arn | Secrets Manager ARN for the RDS-managed master user credentials. |
| rds_master_user_secret_rotation_stack_name | CloudFormation stack name managing the hosted Secrets Manager rotation Lambda for the RDS master user secret. |
| rds_multi_az_enabled | Whether the workload RDS instance is deployed in Multi-AZ mode. |
| rds_security_group_id | n/a |
| representative_resource_tags | Representative effective tag contracts for the VPC, RDS instance, and frontend CloudFront distribution. |
| route53_zone_id_effective | Route53 hosted zone ID used for public DNS records. |
| route53_zone_managed | Whether Terraform created and therefore manages the public hosted zone. |
| route53_zone_name_effective | Route53 hosted zone name discovered or managed for public DNS records. |
| s3_access_logs_bucket_name | Centralized S3 server access logs bucket. |
| security_baseline_access_analyzer_arn | IAM Access Analyzer ARN from the security baseline module. |
| security_baseline_backup_plan_id | Compatibility alias for the per-root AWS Backup plan ID. |
| security_baseline_backup_vault_name | Compatibility alias for the per-root AWS Backup vault name. |
| security_baseline_cloudtrail_arn | CloudTrail ARN from the security baseline module. |
| security_baseline_config_recorder_name | AWS Config recorder name from the security baseline module. |
| security_baseline_ecs_exec_audit_event_rule_name | EventBridge rule name forwarding ECS Exec invocations to the security notifications topic. |
| security_baseline_findings_sns_topic_arn | SNS topic ARN receiving GuardDuty/Security Hub high-severity findings. |
| security_baseline_guardduty_detector_id | Account-local GuardDuty detector ID for the deployment. |
| security_baseline_inspector_resource_types | Amazon Inspector enabled resource types from the security baseline module. |
| security_baseline_log_bucket_dr_name | Security baseline DR S3 log bucket name. |
| security_baseline_log_bucket_name | Security baseline S3 log bucket name. |
| service_discovery_namespace_name | Cloud Map private DNS namespace used in gateway_microservices mode. |
| vpc_flow_logs_log_group_name | VPC Flow Logs log group name. |
| vpc_id | n/a |
<!-- END_TF_DOCS -->
