# cloudfront_backend

Reusable Terraform module for the backend CloudFront distribution in front of the private ALB origin.

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
| [aws_cloudfront_distribution.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access_logs_bucket | S3 bucket domain name for CloudFront logs (for example bucket.s3.amazonaws.com) | `string` | n/a | yes |
| backend_alias | Alias for backend CloudFront | `string` | n/a | yes |
| backend_cert_arn | ACM certificate ARN for backend | `string` | n/a | yes |
| backend_domain_name | Primary backend origin domain name | `string` | n/a | yes |
| backend_failover_domain_name | Secondary backend origin domain name used for CloudFront origin failover | `string` | n/a | yes |
| cache_policy_id | CloudFront cache policy ID | `string` | n/a | yes |
| origin_request_policy_id | CloudFront origin request policy ID | `string` | n/a | yes |
| access_logs_prefix | Prefix used for backend CloudFront log objects | `string` | `"cloudfront/backend/"` | no |
| allowed_methods | HTTP methods accepted by the backend distribution. | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD",<br/>  "OPTIONS",<br/>  "PUT",<br/>  "POST",<br/>  "PATCH",<br/>  "DELETE"<br/>]</pre> | no |
| app_port | Backend ALB listener port used by CloudFront origin | `number` | `8080` | no |
| backend_failover_protocol_policy | CloudFront-to-secondary-origin protocol policy | `string` | `"https-only"` | no |
| backend_vpc_origin_id | Optional CloudFront VPC origin ID for the primary backend origin. | `string` | `null` | no |
| enable_environment_suffix | Suffix aliases and tags with environment | `bool` | `false` | no |
| enable_origin_auth_header | Enable custom origin authentication headers | `bool` | `true` | no |
| enable_origin_failover | Enable CloudFront origin-group failover when the backend is read-only. Mutating API methods automatically disable origin groups. | `bool` | `false` | no |
| environment_name_override | Optional explicit environment name used for naming and tagging. Leave null to derive it from the current Terraform context. | `string` | `null` | no |
| geo_locations | ISO 3166-1 alpha-2 country codes used when geo_restriction_type is whitelist or blacklist. | `list(string)` | `[]` | no |
| geo_restriction_type | CloudFront geo restriction mode: none, whitelist, or blacklist. | `string` | `"none"` | no |
| origin_auth_header_name | Primary custom header name for origin auth | `string` | `"X-Origin-Verify"` | no |
| origin_auth_header_value | Primary custom header value for origin auth | `string` | `""` | no |
| origin_auth_previous_header_name | Secondary custom header name for origin auth rotation | `string` | `"X-Origin-Verify-Prev"` | no |
| origin_auth_previous_header_value | Secondary custom header value for origin auth rotation | `string` | `""` | no |
| origin_protocol_policy | CloudFront-to-origin protocol policy | `string` | `"https-only"` | no |
| price_class | CloudFront price class | `string` | `"PriceClass_100"` | no |
| response_headers_policy_id | Response headers policy ID for backend default cache behavior | `string` | `"67f7725c-6f97-4210-82d7-5512b31e9d03"` | no |
| viewer_protocol_policy | Viewer protocol policy for the backend distribution default cache behavior | `string` | `"redirect-to-https"` | no |
| web_acl_id | Optional WAFv2 Web ACL ARN | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| backend_distribution_arn | n/a |
| backend_distribution_id | n/a |
| backend_hosted_zone_id | n/a |
| backend_url | n/a |
<!-- END_TF_DOCS -->
