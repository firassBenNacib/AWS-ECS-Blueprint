# s3

Reusable Terraform module for private S3 content delivery buckets, logging, and replication controls.

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
| terraform | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.frontend_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.frontend_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.frontend_ownership](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_public_access_block.frontend_public_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.frontend_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.frontend_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [terraform_data.access_logging_prerequisites](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.replication_prerequisites](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | S3 bucket name for hosting frontend | `string` | n/a | yes |
| access_logging_prerequisite_ids | Opaque dependency IDs that must exist before access logging is configured. | `list(string)` | `[]` | no |
| access_logging_target_bucket_name | Optional bucket name receiving S3 server access logs for this bucket. | `string` | `null` | no |
| access_logging_target_prefix | Prefix used for S3 server access logs when access logging is enabled. | `string` | `"s3-access/frontend/"` | no |
| enable_access_logging | Enable S3 server access logging for this bucket. | `bool` | `false` | no |
| enable_kms_encryption | Use SSE-KMS for bucket encryption instead of SSE-S3 | `bool` | `false` | no |
| enable_lifecycle | Enable lifecycle policy on the bucket | `bool` | `false` | no |
| enable_replication | Enable cross-region bucket replication. | `bool` | `false` | no |
| force_destroy | Allow destroying non-empty S3 bucket | `bool` | `false` | no |
| kms_key_id | KMS key ID/ARN for SSE-KMS encryption | `string` | `null` | no |
| lifecycle_abort_incomplete_multipart_upload_days | Abort incomplete multipart uploads after this many days | `number` | `7` | no |
| lifecycle_expiration_days | Optional expiration age for current objects | `number` | `null` | no |
| lifecycle_noncurrent_expiration_days | Optional expiration age for noncurrent object versions | `number` | `30` | no |
| replication_destination_bucket_arn | Optional destination bucket ARN for cross-region replication. | `string` | `null` | no |
| replication_prerequisite_ids | Opaque dependency IDs that must exist before replication is configured. | `list(string)` | `[]` | no |
| replication_replica_kms_key_id | Optional replica-region KMS key ARN used for replicated objects. | `string` | `null` | no |
| replication_role_arn | Optional IAM role ARN used for bucket replication. | `string` | `null` | no |
| versioning_enabled | Enable bucket versioning | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_arn | Frontend S3 bucket ARN. |
| bucket_domain_name | Frontend S3 bucket regional domain name used for CloudFront origin. |
| bucket_name | Frontend S3 bucket name. |
<!-- END_TF_DOCS -->
