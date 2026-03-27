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
| terraform | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| s3 | ../../../s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.frontend_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.frontend_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.frontend_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.frontend_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.frontend_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.frontend_dr_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.frontend_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_public_access_block.frontend_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.frontend_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.frontend_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [terraform_data.frontend_dr_access_logging_prerequisite](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Normalized environment naming inputs. | <pre>object({<br/>    name          = string<br/>    enable_suffix = bool<br/>  })</pre> | n/a | yes |
| frontend | Resolved frontend content storage inputs. | <pre>object({<br/>    runtime_is_s3                                    = bool<br/>    bucket_name                                      = string<br/>    dr_bucket_name                                   = string<br/>    force_destroy                                    = bool<br/>    versioning_enabled                               = bool<br/>    enable_kms_encryption                            = bool<br/>    primary_kms_key_arn                              = string<br/>    dr_kms_key_arn                                   = string<br/>    enable_access_logging                            = bool<br/>    primary_access_logging_target_bucket_name        = string<br/>    primary_access_logging_prerequisite_id           = string<br/>    primary_access_logging_target_prefix             = string<br/>    dr_access_logging_target_bucket_name             = string<br/>    dr_access_logging_prerequisite_id                = string<br/>    enable_lifecycle                                 = bool<br/>    lifecycle_expiration_days                        = number<br/>    lifecycle_noncurrent_expiration_days             = number<br/>    lifecycle_abort_incomplete_multipart_upload_days = number<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| frontend_dr_bucket_arn | n/a |
| frontend_dr_bucket_domain | n/a |
| frontend_dr_bucket_name | n/a |
| frontend_primary_bucket_arn | n/a |
| frontend_primary_bucket_domain | n/a |
| frontend_primary_bucket_name | n/a |
<!-- END_TF_DOCS -->