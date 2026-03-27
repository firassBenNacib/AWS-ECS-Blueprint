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
| [aws_s3_bucket_policy.frontend_dr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.frontend_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| frontend | Resolved frontend bucket-policy inputs. | <pre>object({<br/>    runtime_is_s3                = bool<br/>    frontend_primary_bucket_name = string<br/>    frontend_primary_bucket_arn  = string<br/>    frontend_dr_bucket_name      = string<br/>    frontend_dr_bucket_arn       = string<br/>    distribution_arn             = string<br/>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->