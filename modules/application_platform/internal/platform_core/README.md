<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0, < 2.0.0 |
| aws | >= 6.0, < 7.0 |
| external | >= 2.3, < 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0, < 7.0 |
| aws.dr | >= 6.0, < 7.0 |
| external | >= 2.3, < 3.0 |
| null | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.ecs_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.s3_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.s3_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.ecs_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.s3_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.s3_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_route53_zone.environment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [null_resource.guardrails](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Normalized environment and Route53 inputs for the shared platform-core layer. | <pre>object({<br/>    name                  = string<br/>    domain                = string<br/>    route53_zone_id_input = string<br/>    route53_zone_strategy = string<br/>    live_validation_mode  = bool<br/>    live_validation_label = string<br/>  })</pre> | n/a | yes |
| guardrails | Resolved guardrail inputs from the wrapper. | `any` | n/a | yes |
| kms | KMS configuration inputs owned by the application_platform wrapper. | <pre>object({<br/>    project_name              = string<br/>    aws_region                = string<br/>    dr_region                 = string<br/>    create_primary_s3_kms_key = bool<br/>    create_dr_s3_kms_key      = bool<br/>    s3_kms_key_id             = string<br/>    dr_s3_kms_key_id          = string<br/>    enable_ecs_exec           = bool<br/>  })</pre> | n/a | yes |
| origin_auth | Origin-auth SSM parameter inputs. | <pre>object({<br/>    enabled                     = bool<br/>    header_ssm_parameter_name   = string<br/>    previous_ssm_parameter_name = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecs_exec_kms_key_arn_final | n/a |
| origin_auth_header_value_resolved | n/a |
| origin_auth_previous_header_value_resolved | n/a |
| route53_zone_id_effective | n/a |
| route53_zone_managed | n/a |
| route53_zone_name_effective | n/a |
| s3_dr_kms_key_arn | n/a |
| s3_primary_kms_key_arn | n/a |
<!-- END_TF_DOCS -->