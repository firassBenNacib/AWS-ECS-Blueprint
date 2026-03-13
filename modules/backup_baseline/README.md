# backup_baseline

Reusable Terraform module for per-root AWS Backup vault, plan, DR copy target, and optional backup selection.

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
| [aws_backup_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_iam_role.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.backup_restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.backup_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix used to name backup resources. | `string` | n/a | yes |
| backup_completion_window_minutes | Backup job completion window in minutes. | `number` | `180` | no |
| backup_copy_retention_days | Retention in days for DR copied recovery points. | `number` | `35` | no |
| backup_cross_region_copy_enabled | Enable cross-region copy of recovery points to the DR vault. | `bool` | `true` | no |
| backup_dr_kms_key_arn | Optional existing KMS key ARN for the DR-region backup vault. Leave unset to let Terraform manage one. | `string` | `null` | no |
| backup_resource_arns | Resource ARNs selected by AWS Backup when enable_backup_selection=true. | `list(string)` | `[]` | no |
| backup_retention_days | Retention in days for primary-region recovery points. | `number` | `35` | no |
| backup_schedule_expression | Cron expression for the AWS Backup rule. | `string` | `"cron(0 5 * * ? *)"` | no |
| backup_start_window_minutes | Backup job start window in minutes. | `number` | `60` | no |
| backup_vault_name | Optional AWS Backup vault base name. When unset, a name is derived from name_prefix. | `string` | `null` | no |
| enable_aws_backup | Enable AWS Backup vault, plan, and optional resource selection. | `bool` | `true` | no |
| enable_backup_selection | Enable AWS Backup resource selection for the supplied resource ARNs. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| backup_plan_id | AWS Backup plan ID. |
| backup_role_arn | AWS Backup service role ARN. |
| backup_vault_name | Primary AWS Backup vault name. |
<!-- END_TF_DOCS -->