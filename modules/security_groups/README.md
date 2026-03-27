# security_groups

Reusable Terraform module for tiered security group boundaries between edge, application, and data resources.

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
| [aws_security_group.backend_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.backend_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.backend_alb_to_backend_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.backend_service_to_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | The ID of the VPC where security groups are created | `string` | n/a | yes |
| alb_listener_port | ALB listener port exposed through CloudFront VPC-origin path | `number` | `443` | no |
| app_port | Backend application port | `number` | `8080` | no |
| egress_endpoint_sg_id | Security group ID attached to Interface VPC Endpoints for private AWS API egress. | `string` | `null` | no |
| egress_s3_prefix_list_id | Managed prefix list ID for Amazon S3 gateway-endpoint egress. | `string` | `null` | no |
| enable_environment_suffix | Suffix security group names with environment | `bool` | `false` | no |
| environment_name_override | Optional explicit environment name used for security-group naming. Leave null to derive it from the current Terraform context. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend_alb_sg_id | Security group ID for backend ALB |
| backend_service_sg_id | Security group ID for backend ECS service tasks |
| rds_sg_id | Security group ID for RDS |
<!-- END_TF_DOCS -->
