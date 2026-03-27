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

| Name | Source | Version |
|------|--------|---------|
| rds | ../../../rds | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack.master_user_secret_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_sns_topic.master_user_secret_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.master_user_secret_rotation_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| data | Resolved RDS configuration inputs. | `any` | n/a | yes |
| environment | Normalized environment naming inputs for data resources. | <pre>object({<br/>    name          = string<br/>    enable_suffix = bool<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| address | n/a |
| endpoint | n/a |
| instance_arn | n/a |
| instance_identifier | n/a |
| master_user_secret_arn | n/a |
| master_user_secret_rotation_stack_name | n/a |
<!-- END_TF_DOCS -->