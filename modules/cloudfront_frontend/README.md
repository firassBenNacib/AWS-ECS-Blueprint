# cloudfront_frontend

Reusable Terraform module for the frontend CloudFront distribution in front of the private S3 origin.

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
| aws | 6.37.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.spa_request_rewrite](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.frontend_oac](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access_logs_bucket | S3 bucket domain name for CloudFront logs (for example bucket.s3.amazonaws.com) | `string` | n/a | yes |
| frontend_aliases | Frontend aliases for CloudFront | `list(string)` | n/a | yes |
| frontend_cert_arn | ACM certificate ARN for frontend | `string` | n/a | yes |
| access_logs_prefix | Prefix used for frontend CloudFront log objects | `string` | `"cloudfront/frontend/"` | no |
| backend_allowed_methods | HTTP methods accepted for backend/API path behaviors. | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD",<br/>  "OPTIONS",<br/>  "PUT",<br/>  "POST",<br/>  "PATCH",<br/>  "DELETE"<br/>]</pre> | no |
| backend_cache_policy_id | CloudFront cache policy ID for backend/API path behaviors. | `string` | `"4135ea2d-6df8-44a3-9df3-4b5a84be39ad"` | no |
| backend_origin_auth_enabled | Attach custom origin-auth headers to the backend origin. | `bool` | `true` | no |
| backend_origin_auth_header_name | Primary custom header name used to authenticate CloudFront to the backend origin. | `string` | `"X-Origin-Verify"` | no |
| backend_origin_auth_header_value | Primary custom header value used to authenticate CloudFront to the backend origin. | `string` | `""` | no |
| backend_origin_auth_previous_header_name | Secondary custom header name used during backend origin-auth rotation. | `string` | `"X-Origin-Verify-Prev"` | no |
| backend_origin_auth_previous_header_value | Secondary custom header value used during backend origin-auth rotation. | `string` | `""` | no |
| backend_origin_domain_name | ALB domain name used as the backend origin when backend_origin_enabled=true. | `string` | `""` | no |
| backend_origin_enabled | When true, add a private ALB origin and ordered cache behaviors for backend/API paths. | `bool` | `false` | no |
| backend_origin_https_port | Backend ALB listener port exposed to CloudFront. | `number` | `443` | no |
| backend_origin_protocol_policy | CloudFront-to-backend origin protocol policy. | `string` | `"https-only"` | no |
| backend_origin_request_policy_id | CloudFront origin request policy ID for backend/API path behaviors. | `string` | `"b689b0a8-53d0-40ab-baf2-68738e2966ac"` | no |
| backend_origin_vpc_origin_id | Optional CloudFront VPC origin ID for the backend ALB origin. | `string` | `null` | no |
| backend_path_patterns | Ordered cache behavior path patterns routed to the private backend origin. | `list(string)` | <pre>[<br/>  "/api/*",<br/>  "/auth/*",<br/>  "/audit/*",<br/>  "/notify/*",<br/>  "/mailer/*",<br/>  "/gateway/*"<br/>]</pre> | no |
| backend_response_headers_policy_id | CloudFront response headers policy ID for backend/API path behaviors. | `string` | `"67f7725c-6f97-4210-82d7-5512b31e9d03"` | no |
| backend_viewer_protocol_policy | Viewer protocol policy for backend/API path cache behaviors. | `string` | `"https-only"` | no |
| cache_policy_id | CloudFront cache policy ID | `string` | `"658327ea-f89d-4fab-a63d-7e88639e58f6"` | no |
| enable_environment_suffix | Suffix frontend aliases and tags with environment | `bool` | `false` | no |
| enable_spa_routing | Rewrite non-asset frontend routes to /index.html at the edge so SPA deep links work without affecting API paths. | `bool` | `true` | no |
| environment_domain | Base domain used to derive environment aliases | `string` | `""` | no |
| environment_name_override | Optional explicit environment name used for naming and alias derivation. Leave null to derive it from the current Terraform context. | `string` | `null` | no |
| frontend_alb_domain_name | ALB domain name used as frontend origin when frontend_runtime_mode=ecs. | `string` | `""` | no |
| frontend_alb_https_port | Frontend ALB HTTPS listener port when frontend_runtime_mode=ecs. | `number` | `443` | no |
| frontend_bucket_domain | S3 bucket domain name | `string` | `""` | no |
| frontend_runtime_mode | Frontend runtime mode: s3 (S3+CloudFront) or ecs (CloudFront to ALB/ECS). | `string` | `"s3"` | no |
| frontend_vpc_origin_id | Optional CloudFront VPC origin ID for the frontend ALB origin when frontend_runtime_mode=ecs. | `string` | `null` | no |
| geo_locations | ISO 3166-1 alpha-2 country codes used when geo_restriction_type is whitelist or blacklist. | `list(string)` | `[]` | no |
| geo_restriction_type | CloudFront geo restriction mode for the frontend distribution: none, whitelist, or blacklist. | `string` | `"none"` | no |
| price_class | CloudFront price class | `string` | `"PriceClass_100"` | no |
| response_headers_policy_id | CloudFront response headers policy ID | `string` | `"67f7725c-6f97-4210-82d7-5512b31e9d03"` | no |
| secondary_bucket_domain | DR S3 bucket domain name used as secondary origin for CloudFront failover | `string` | `""` | no |
| viewer_protocol_policy | Viewer protocol policy for the frontend distribution default cache behavior | `string` | `"https-only"` | no |
| web_acl_id | Optional WAFv2 Web ACL ARN | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| frontend_distribution_arn | n/a |
| frontend_distribution_id | n/a |
| frontend_hosted_zone_id | n/a |
| frontend_url | n/a |
<!-- END_TF_DOCS -->
