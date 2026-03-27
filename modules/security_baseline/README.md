# security_baseline

Reusable Terraform module for account-level security controls:

- multi-region CloudTrail with log validation
- optional CloudTrail data-event selectors
- AWS Config recorder and delivery channel
- Security Hub + standards subscriptions
- IAM Access Analyzer
- Amazon Inspector
- findings routing to SNS/EventBridge
- audit-log buckets, replication, and related KMS/logging controls

AWS Backup resources are no longer owned by this module. Per-root backup vaults, plans, and selections now live in [`modules/backup_baseline`](../backup_baseline/README.md).

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
| aws.dr | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_accessanalyzer_analyzer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/accessanalyzer_analyzer) | resource |
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_event_rule.ecs_exec_invocations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.guardduty_high_critical](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.securityhub_high_critical](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ecs_exec_invocations_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.guardduty_high_critical_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.securityhub_high_critical_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_role.cloudtrail_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.logs_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudtrail_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.logs_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_inspector2_enabler.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_enabler) | resource |
| [aws_kms_alias.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_logging.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.logs_dr_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_notification.logs_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_object_lock_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_ownership_controls.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_securityhub_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_standards_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription) | resource |
| [aws_sns_topic.cloudtrail_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.security_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.cloudtrail_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_policy.security_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.security_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| log_bucket_name | S3 bucket name used for CloudTrail and AWS Config delivery | `string` | n/a | yes |
| name_prefix | Prefix used to name security baseline resources | `string` | n/a | yes |
| access_logs_bucket_name | Optional central S3 access-log sink bucket name used for baseline log bucket server access logs | `string` | `null` | no |
| access_logs_bucket_name_dr | Optional DR-region S3 access-log sink bucket name used for the replicated baseline log bucket server access logs. | `string` | `null` | no |
| cloudtrail_data_event_resources | CloudTrail data-event resource ARNs (for example arn:aws:s3:::bucket-name/). | `list(string)` | `[]` | no |
| cloudtrail_retention_days | Retention in days for lifecycle cleanup in the security baseline log bucket | `number` | `365` | no |
| enable_access_analyzer | Enable IAM Access Analyzer | `bool` | `true` | no |
| enable_aws_config | Enable AWS Config recorder and delivery channel. | `bool` | `true` | no |
| enable_cloudtrail_data_events | Enable CloudTrail data event selectors for high-value resources. | `bool` | `false` | no |
| enable_ecs_exec_audit_alerts | Enable EventBridge alerts for ECS Exec shell access observed via CloudTrail. | `bool` | `false` | no |
| enable_inspector | Enable Amazon Inspector account scanning. | `bool` | `true` | no |
| enable_log_bucket_object_lock | Enable S3 Object Lock on the primary security baseline log bucket. | `bool` | `false` | no |
| enable_security_hub | Enable Security Hub account integration and standards subscriptions | `bool` | `true` | no |
| inspector_resource_types | Amazon Inspector resource types to enable for account scanning. | `list(string)` | <pre>[<br/>  "ECR",<br/>  "EC2"<br/>]</pre> | no |
| log_bucket_dr_name | Optional DR-region replica bucket name for security baseline logs. When unset, Terraform derives one from log_bucket_name and dr_region. | `string` | `null` | no |
| log_bucket_force_destroy | Force deletion of security baseline log buckets during teardown. | `bool` | `false` | no |
| object_lock_days | S3 Object Lock GOVERNANCE-mode retention period in days for the CloudTrail/Config log bucket. Prevents accidental deletion of audit logs. | `number` | `365` | no |
| security_findings_sns_subscriptions | Optional managed-topic SNS subscriptions for security findings. | <pre>list(object({<br/>    protocol = string<br/>    endpoint = string<br/>  }))</pre> | `[]` | no |
| security_findings_sns_topic_arn | Optional existing SNS topic ARN for GuardDuty/Security Hub high/critical findings. When null, a managed topic is created. | `string` | `null` | no |
| securityhub_standards | Security Hub standards ARNs to subscribe to | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| access_analyzer_arn | IAM Access Analyzer ARN |
| cloudtrail_arn | ARN of the multi-region CloudTrail |
| cloudtrail_name | Name of the CloudTrail trail |
| config_recorder_name | AWS Config recorder name |
| ecs_exec_audit_event_rule_name | EventBridge rule name forwarding ECS Exec invocations to security notifications. |
| inspector_enabled_resource_types | Amazon Inspector enabled resource types. |
| log_bucket_dr_name | DR-region replica bucket used for security baseline logs. |
| log_bucket_name | S3 bucket used for security baseline logs |
| security_findings_event_rule_names | EventBridge rule names forwarding high-severity security findings. |
| security_findings_sns_topic_arn | SNS topic ARN receiving GuardDuty/Security Hub high-severity findings. |
| securityhub_account_id | Security Hub account ID |
| securityhub_standards_subscription_arns | Security Hub standards subscription ARNs |
<!-- END_TF_DOCS -->
