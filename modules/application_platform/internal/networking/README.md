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
| network | ../../../network | n/a |
| security_groups | ../../../security_groups | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.microservices_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.microservices_extra_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.microservices_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.microservices_internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.microservices_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.microservices_alb_to_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Normalized environment naming inputs for network and security resources. | <pre>object({<br/>    name          = string<br/>    enable_suffix = bool<br/>  })</pre> | n/a | yes |
| network | Resolved network inputs for the shared VPC module. | `any` | n/a | yes |
| security | Resolved security-group inputs for runtime modes. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| backend_alb_security_group_id | n/a |
| backend_service_security_group_id | n/a |
| interface_endpoints_sg_id | n/a |
| microservices_alb_security_group_id | n/a |
| microservices_extra_egress_security_group_ids | n/a |
| microservices_gateway_security_group_id | n/a |
| microservices_internal_security_group_id | n/a |
| private_app_subnet_ids | n/a |
| private_db_subnet_ids | n/a |
| public_edge_subnet_ids | n/a |
| rds_security_group_id | n/a |
| s3_gateway_prefix_list_id | n/a |
| vpc_flow_logs_log_group_name | n/a |
| vpc_id | n/a |
<!-- END_TF_DOCS -->