# alb

Reusable Terraform module for the internal application load balancer, listeners, and target groups.

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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.origin_auth_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.origin_auth_secondary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access_logs_bucket | S3 bucket name where ALB access logs are stored | `string` | n/a | yes |
| alb_security_group_id | Security group ID attached to ALB | `string` | n/a | yes |
| alb_subnet_ids | Subnet IDs used by ALB | `list(string)` | n/a | yes |
| certificate_arn | Regional ACM certificate ARN for ALB HTTPS listener | `string` | n/a | yes |
| vpc_id | VPC ID where ALB and target group are created | `string` | n/a | yes |
| access_logs_prefix | Prefix for ALB access log objects | `string` | `"alb/"` | no |
| alb_listener_port | Primary ALB HTTPS listener port | `number` | `443` | no |
| alb_name | ALB name base | `string` | `"app-backend-alb"` | no |
| app_port | Backend application port used by target group | `number` | `8080` | no |
| enable_deletion_protection | Enable ALB deletion protection | `bool` | `false` | no |
| enable_environment_suffix | Suffix ALB resources with environment | `bool` | `false` | no |
| enable_origin_auth_header | Enable CloudFront origin custom-header enforcement at ALB listener level | `bool` | `true` | no |
| environment_name_override | Optional explicit environment name used for ALB resource naming. Leave null to derive it from the current Terraform context. | `string` | `null` | no |
| health_check_healthy_threshold | ALB target group healthy threshold count | `number` | `2` | no |
| health_check_interval_seconds | ALB target group health check interval | `number` | `30` | no |
| health_check_matcher | ALB target group health check matcher | `string` | `"200-399"` | no |
| health_check_path | ALB target group health check path | `string` | `"/health"` | no |
| health_check_timeout_seconds | ALB target group health check timeout | `number` | `5` | no |
| health_check_unhealthy_threshold | ALB target group unhealthy threshold count | `number` | `3` | no |
| idle_timeout | ALB idle timeout in seconds | `number` | `60` | no |
| internal | Whether the ALB is internal-only. | `bool` | `true` | no |
| origin_auth_header_name | Primary origin auth header name accepted by ALB listener rules | `string` | `"X-Origin-Verify"` | no |
| origin_auth_header_value | Primary origin auth header value accepted by ALB listener rules | `string` | `""` | no |
| origin_auth_previous_header_name | Secondary origin auth header name accepted during header rotation | `string` | `"X-Origin-Verify-Prev"` | no |
| origin_auth_previous_header_value | Secondary origin auth header value accepted during header rotation | `string` | `""` | no |
| ssl_policy | SSL policy for ALB HTTPS listener | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| target_group_name | Target group name base | `string` | `"app-backend-tg"` | no |
| target_type | Target type for ALB target group. ECS Fargate requires ip. | `string` | `"ip"` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | Backend ALB ARN |
| alb_arn_suffix | Backend ALB ARN suffix used for CloudWatch metrics dimensions. |
| alb_dns_name | Backend ALB DNS name |
| alb_zone_id | Backend ALB hosted zone ID |
| target_group_arn | Backend ALB target group ARN |
| target_group_arn_suffix | Backend target group ARN suffix used for CloudWatch metrics dimensions. |
<!-- END_TF_DOCS -->
