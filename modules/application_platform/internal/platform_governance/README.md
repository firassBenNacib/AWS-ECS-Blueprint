<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0, < 2.0.0 |
| aws | >= 6.0, < 7.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| backup_baseline | ../../../backup_baseline | n/a |
| budget_alerts | ../../../budget_alerts | n/a |
| guardduty_member_detector | ../../../guardduty_member_detector | n/a |
| security_baseline | ../../../security_baseline | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| backup | Resolved AWS Backup inputs. | `any` | n/a | yes |
| budget | Resolved AWS Budgets alert inputs. | `any` | n/a | yes |
| security | Resolved security baseline inputs. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| access_analyzer_arn | n/a |
| backup_plan_id | n/a |
| backup_vault_name | n/a |
| budget_arns | n/a |
| budget_names | n/a |
| cloudtrail_arn | n/a |
| config_recorder_name | n/a |
| detector_id | n/a |
| ecs_exec_audit_event_rule_name | n/a |
| inspector_enabled_resource_types | n/a |
| log_bucket_dr_name | n/a |
| log_bucket_name | n/a |
| security_findings_sns_topic_arn | n/a |
<!-- END_TF_DOCS -->