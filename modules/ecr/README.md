# ecr

Reusable Terraform module for ECR repository creation, lifecycle policies, and image scanning.

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
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repository_name | ECR repository name | `string` | n/a | yes |
| encryption_kms_key_arn | Optional KMS key ARN for ECR encryption. When null, alias/aws/ecr is used. | `string` | `null` | no |
| max_image_count | Maximum number of images retained by lifecycle policy | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_arn | ECR repository ARN |
| repository_name | ECR repository name |
| repository_url | ECR repository URL |
<!-- END_TF_DOCS -->
