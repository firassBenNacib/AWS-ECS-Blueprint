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
| cloudfront_frontend | ../../../cloudfront_frontend | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_response_headers_policy.secure_defaults](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |
| [aws_route53_record.frontend_root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.frontend_www](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| backend | Resolved backend path-routing inputs embedded in the frontend distribution. | <pre>object({<br/>    origin_enabled                    = bool<br/>    origin_domain_name                = string<br/>    origin_vpc_origin_id              = string<br/>    origin_https_port                 = number<br/>    origin_protocol_policy            = string<br/>    viewer_protocol_policy            = string<br/>    cache_policy_id                   = string<br/>    origin_request_policy_id          = string<br/>    allowed_methods                   = list(string)<br/>    path_patterns                     = list(string)<br/>    origin_auth_enabled               = bool<br/>    origin_auth_header_name           = string<br/>    origin_auth_header_value          = string<br/>    origin_auth_previous_header_name  = string<br/>    origin_auth_previous_header_value = string<br/>  })</pre> | n/a | yes |
| environment | Normalized environment naming inputs for frontend edge resources. | <pre>object({<br/>    name          = string<br/>    enable_suffix = bool<br/>    domain        = string<br/>    project_name  = string<br/>  })</pre> | n/a | yes |
| frontend | Resolved frontend distribution inputs. | <pre>object({<br/>    bucket_domain           = string<br/>    secondary_bucket_domain = string<br/>    aliases                 = list(string)<br/>    cert_arn                = string<br/>    cache_policy_id         = string<br/>    price_class             = string<br/>    viewer_protocol_policy  = string<br/>    geo_restriction_type    = string<br/>    geo_locations           = list(string)<br/>    access_logs_bucket      = string<br/>    access_logs_prefix      = string<br/>    runtime_mode            = string<br/>    alb_domain_name         = string<br/>    vpc_origin_id           = string<br/>    alb_https_port          = number<br/>  })</pre> | n/a | yes |
| route53_zone_id_effective | Hosted zone ID used for frontend public aliases. | `string` | n/a | yes |
| web_acl_id | Optional CloudFront Web ACL ARN. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| frontend_distribution_arn | n/a |
| frontend_distribution_id | n/a |
| frontend_hosted_zone_id | n/a |
| frontend_url | n/a |
<!-- END_TF_DOCS -->