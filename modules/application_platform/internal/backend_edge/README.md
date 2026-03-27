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
| aws.us_east_1 | >= 6.0, < 7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| alb | ../../../alb | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_vpc_origin.backend_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_vpc_origin) | resource |
| [aws_cloudwatch_log_group.waf_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.waf_cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_security_group_rule.microservices_cloudfront_prefix_to_alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.microservices_cloudfront_to_alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_wafv2_web_acl.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.alb_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_association.alb_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_wafv2_web_acl_logging_configuration.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb_config | Resolved ALB configuration inputs. | <pre>object({<br/>    certificate_arn                  = string<br/>    ssl_policy                       = string<br/>    health_check_matcher             = string<br/>    health_check_interval_seconds    = number<br/>    health_check_timeout_seconds     = number<br/>    health_check_healthy_threshold   = number<br/>    health_check_unhealthy_threshold = number<br/>    alb_name                         = string<br/>    target_group_name                = string<br/>    deletion_protection              = bool<br/>    idle_timeout                     = number<br/>    access_logs_bucket               = string<br/>    access_logs_prefix               = string<br/>  })</pre> | n/a | yes |
| environment | Normalized environment naming inputs for backend edge resources. | <pre>object({<br/>    name          = string<br/>    enable_suffix = bool<br/>  })</pre> | n/a | yes |
| ingress | Resolved backend ingress and ALB wiring inputs. | <pre>object({<br/>    selected_vpc_id                     = string<br/>    selected_alb_subnet_ids             = list(string)<br/>    backend_ingress_is_vpc_origin       = bool<br/>    backend_ingress_is_public           = bool<br/>    runtime_mode_is_micro               = bool<br/>    alb_security_group_id               = string<br/>    microservices_alb_security_group_id = string<br/>    alb_app_port                        = number<br/>    alb_health_check_path               = string<br/>    alb_listener_port                   = number<br/>    backend_origin_protocol_policy      = string<br/>    origin_auth_enabled                 = bool<br/>    origin_auth_header_name             = string<br/>    origin_auth_header_value            = string<br/>    origin_auth_previous_header_name    = string<br/>    origin_auth_previous_header_value   = string<br/>  })</pre> | n/a | yes |
| waf_config | Resolved WAF configuration inputs for ALB and CloudFront. | <pre>object({<br/>    create_managed_alb        = bool<br/>    create_managed_cloudfront = bool<br/>    rate_limit_requests       = number<br/>    log_retention_days        = number<br/>    alb_web_acl_arn           = string<br/>    frontend_web_acl_arn      = string<br/>    backend_web_acl_arn       = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | n/a |
| alb_arn_suffix | n/a |
| alb_dns_name | n/a |
| alb_zone_id | n/a |
| backend_vpc_origin_id_final | n/a |
| cloudfront_web_acl_arn | n/a |
| target_group_arn | n/a |
| target_group_arn_suffix | n/a |
<!-- END_TF_DOCS -->