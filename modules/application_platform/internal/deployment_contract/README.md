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
| settings | n/a | <pre>object({<br/>    environment_name_override        = string<br/>    app_runtime_mode                 = string<br/>    backend_ingress_mode             = string<br/>    frontend_runtime_mode            = string<br/>    enable_security_baseline         = bool<br/>    enable_account_security_controls = bool<br/>    enable_environment_suffix        = bool<br/>    environment_domain               = string<br/>    route53_zone_id                  = string<br/>    live_validation_dns_label        = string<br/>    live_validation_mode             = bool<br/>    bucket_name                      = string<br/>    s3_access_logs_bucket_name       = string<br/>    cloudfront_logs_bucket_name      = string<br/>    dr_frontend_bucket_name          = string<br/>    dr_cloudfront_logs_bucket_name   = string<br/>    s3_kms_key_id                    = string<br/>    dr_s3_kms_key_id                 = string<br/>    destroy_mode_enabled             = bool<br/>    s3_force_destroy                 = bool<br/>    alb_deletion_protection          = bool<br/>    backend_ecr_repository_name      = string<br/>    project_name                     = string<br/>    account_id                       = string<br/>    partition                        = string<br/>    aws_region                       = string<br/>    dr_region                        = string<br/>    securityhub_standards_arns       = list(string)<br/>    allowed_image_registries         = list(string)<br/>    backend_container_image          = string<br/>    service_discovery_namespace_name = string<br/>    alb_access_logs_prefix           = string<br/>    enable_managed_waf               = bool<br/>    alb_web_acl_arn                  = string<br/>    frontend_web_acl_arn             = string<br/>    backend_web_acl_arn              = string<br/>  })</pre> | n/a | yes |
| workspace_name | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| account_security_controls_enabled | n/a |
| alb_access_logs_bucket_name_final | n/a |
| alb_access_logs_dr_bucket_name_final | n/a |
| alb_access_logs_path | n/a |
| alb_access_logs_prefix | n/a |
| allowed_image_registries_final | n/a |
| backend_ecr_repository_name_final | n/a |
| backend_image_repository | n/a |
| backend_ingress_is_public | n/a |
| backend_ingress_is_vpc_origin | n/a |
| backend_path_patterns | n/a |
| bucket_name_final | n/a |
| create_dr_s3_kms_key | n/a |
| create_managed_waf_alb | n/a |
| create_managed_waf_cloudfront | n/a |
| create_primary_s3_kms_key | n/a |
| dr_cloudfront_logs_bucket_name_final | n/a |
| dr_frontend_bucket_name_final | n/a |
| effective_alb_deletion_protection | n/a |
| effective_s3_force_destroy | n/a |
| enable_environment_suffix | n/a |
| environment_domain | n/a |
| environment_name | n/a |
| frontend_aliases | n/a |
| frontend_dr_bucket_arn_expected | n/a |
| frontend_primary_bucket_arn_expected | n/a |
| frontend_runtime_is_s3 | n/a |
| is_prod | n/a |
| live_validation_dns_label | n/a |
| microservice_allowed_image_registry_prefixes | n/a |
| microservices_cluster_name_final | n/a |
| microservices_exec_log_group_name | n/a |
| route53_zone_id_input | n/a |
| runtime_mode_is_micro | n/a |
| runtime_mode_is_single | n/a |
| s3_access_logs_bucket_name_final | n/a |
| s3_access_logs_dr_bucket_name_final | n/a |
| securityhub_standards_arns | n/a |
| service_discovery_namespace_name_final | n/a |
| smtp_host_final | n/a |
<!-- END_TF_DOCS -->