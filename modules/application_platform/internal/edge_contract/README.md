<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0, < 2.0.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| frontend | n/a | <pre>object({<br/>    primary_bucket_name    = string<br/>    primary_bucket_domain  = string<br/>    primary_bucket_arn     = string<br/>    dr_bucket_name         = string<br/>    dr_bucket_domain       = string<br/>    dr_bucket_arn          = string<br/>    cloudfront_logs_domain = string<br/>  })</pre> | n/a | yes |
| networking | n/a | <pre>object({<br/>    vpc_id                    = string<br/>    interface_endpoints_sg_id = string<br/>    s3_gateway_prefix_list_id = string<br/>    public_edge_subnet_ids    = list(string)<br/>    private_app_subnet_ids    = list(string)<br/>    private_db_subnet_ids     = list(string)<br/>  })</pre> | n/a | yes |
| routing | n/a | <pre>object({<br/>    frontend_aliases              = list(string)<br/>    backend_path_patterns         = list(string)<br/>    backend_ingress_is_vpc_origin = bool<br/>    route53_zone_id_effective     = string<br/>    route53_zone_name_effective   = string<br/>    route53_zone_managed          = bool<br/>    frontend_runtime_is_s3        = bool<br/>    bucket_name_final             = string<br/>    dr_frontend_bucket_name_final = string<br/>    create_managed_waf_alb        = bool<br/>    create_managed_waf_cloudfront = bool<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| backend_path_patterns | n/a |
| cloudfront_logs_bucket_domain | n/a |
| create_managed_waf_alb | n/a |
| create_managed_waf_cloudfront | n/a |
| dr_frontend_bucket_domain | n/a |
| frontend_aliases | n/a |
| frontend_dr_bucket_arn | n/a |
| frontend_dr_bucket_arn_expected | n/a |
| frontend_dr_bucket_name | n/a |
| frontend_primary_bucket_arn | n/a |
| frontend_primary_bucket_arn_expected | n/a |
| frontend_primary_bucket_domain | n/a |
| frontend_primary_bucket_name | n/a |
| route53_zone_id_effective | n/a |
| route53_zone_managed | n/a |
| route53_zone_name_effective | n/a |
| selected_alb_subnet_ids | n/a |
| selected_db_subnet_ids | n/a |
| selected_interface_endpoints_sg_id | n/a |
| selected_private_app_subnet_ids | n/a |
| selected_public_edge_subnet_ids | n/a |
| selected_s3_gateway_prefix_list_id | n/a |
| selected_vpc_id | n/a |
<!-- END_TF_DOCS -->