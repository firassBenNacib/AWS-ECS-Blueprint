# rds

Reusable Terraform module for the application database, subnet group, parameter group, and secret integration.

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
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_role.enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| db_name | Database name | `string` | n/a | yes |
| db_subnet_ids | Private subnet IDs for RDS subnet group | `list(string)` | n/a | yes |
| rds_sg_id | Security group ID for RDS | `string` | n/a | yes |
| username | Master username | `string` | n/a | yes |
| allocated_storage | Allocated storage in GB | `number` | `20` | no |
| backup_retention_period | RDS backup retention in days | `number` | `14` | no |
| deletion_protection | Enable deletion protection on the RDS instance. | `bool` | `true` | no |
| enable_environment_suffix | Suffix RDS identifiers with environment | `bool` | `false` | no |
| enable_iam_database_auth | Enable IAM database authentication | `bool` | `true` | no |
| enable_performance_insights | Enable Performance Insights when the chosen DB engine/class combination supports it. | `bool` | `false` | no |
| enabled_cloudwatch_logs_exports | RDS log types exported to CloudWatch Logs | `list(string)` | <pre>[<br/>  "audit",<br/>  "error",<br/>  "general",<br/>  "slowquery"<br/>]</pre> | no |
| engine_version | RDS engine version for the MySQL instance. | `string` | `"8.0.45"` | no |
| environment_name_override | Optional explicit environment name used for RDS naming. Leave null to derive it from the current Terraform context. | `string` | `null` | no |
| final_snapshot_identifier | Optional final snapshot identifier used on instance deletion | `string` | `null` | no |
| identifier | RDS instance identifier | `string` | `"app-rds"` | no |
| instance_class | RDS instance class | `string` | `"db.t4g.micro"` | no |
| kms_key_id | KMS Key ARN for encryption | `string` | `null` | no |
| manage_master_user_password | Enable RDS-managed master user password stored in Secrets Manager | `bool` | `true` | no |
| master_user_secret_kms_key_id | Optional KMS key ARN for RDS-managed master user secret | `string` | `null` | no |
| max_allocated_storage | Maximum allocated storage in GB for autoscaling. Set to 0 to disable. | `number` | `0` | no |
| monitoring_interval_seconds | Enhanced monitoring interval in seconds (0 disables enhanced monitoring) | `number` | `60` | no |
| multi_az | Enable Multi-AZ deployment for the RDS instance. | `bool` | `true` | no |
| password | Master password (required only when manage_master_user_password=false) | `string` | `null` | no |
| performance_insights_kms_key_id | Optional KMS key ARN for Performance Insights | `string` | `null` | no |
| preferred_backup_window | Daily time range during which automated backups are created (UTC). | `string` | `"03:00-04:00"` | no |
| preferred_maintenance_window | Weekly time range during which system maintenance can occur (UTC). | `string` | `"sun:04:30-sun:05:30"` | no |
| skip_final_snapshot | Skip the final snapshot on instance deletion. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| address | RDS hostname without port |
| db_subnet_group_name | RDS DB subnet group name |
| endpoint | RDS endpoint |
| instance_arn | RDS instance ARN |
| instance_id | RDS instance ID |
| instance_identifier | RDS instance identifier |
| master_user_secret_arn | Secrets Manager ARN for RDS-managed master user credentials |
| port | RDS listener port |
<!-- END_TF_DOCS -->
