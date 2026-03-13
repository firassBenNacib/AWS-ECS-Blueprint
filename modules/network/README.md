# network

Reusable Terraform module for VPC networking, subnets, routes, endpoints, and flow logs.

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
| [aws_cloudwatch_log_group.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.lockdown](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_app_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_edge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_edge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.interface_endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_edge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| availability_zones | Availability zones used by the network | `list(string)` | n/a | yes |
| private_app_subnet_cidrs | CIDR blocks for private app subnets (backend service tasks) | `list(string)` | n/a | yes |
| private_db_subnet_cidrs | CIDR blocks for private DB subnets | `list(string)` | n/a | yes |
| public_app_subnet_cidrs | CIDR blocks for public edge subnets (ALB/NAT) | `list(string)` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| flow_logs_kms_key_id | KMS key ARN used to encrypt VPC Flow Logs CloudWatch log group | `string` | `null` | no |
| flow_logs_retention_days | Retention days for the VPC Flow Logs CloudWatch log group | `number` | `365` | no |
| interface_endpoint_services | AWS service short names used to create Interface VPC Endpoints for private Fargate runtime dependencies. | `list(string)` | <pre>[<br/>  "ecr.api",<br/>  "ecr.dkr",<br/>  "logs",<br/>  "sts",<br/>  "secretsmanager",<br/>  "kms"<br/>]</pre> | no |
| lockdown_default_security_group | When true, removes all rules from the default security group for this VPC | `bool` | `true` | no |
| private_app_nat_mode | Private app subnet internet egress mode: required (all subnets via NAT), canary (single-subnet NAT route), or disabled (no NAT default route). | `string` | `"required"` | no |
| vpc_name | Name tag for the VPC | `string` | `"app-vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| interface_endpoints_sg_id | Security group ID attached to Interface VPC Endpoints |
| nat_gateway_ids | NAT gateway IDs used for private app egress |
| private_app_subnet_ids | Private subnet IDs used by backend service tasks |
| private_db_subnet_ids | Private subnet IDs used by RDS |
| public_app_subnet_ids | Legacy alias of public_edge_subnet_ids |
| public_edge_subnet_ids | Public subnet IDs used by ALB and NAT gateways |
| s3_gateway_endpoint_id | Gateway VPC Endpoint ID for Amazon S3 |
| s3_gateway_prefix_list_id | Managed prefix list ID for Amazon S3 in the current region |
| vpc_flow_logs_log_group_name | VPC Flow Logs CloudWatch log group name |
| vpc_id | VPC ID |
<!-- END_TF_DOCS -->
