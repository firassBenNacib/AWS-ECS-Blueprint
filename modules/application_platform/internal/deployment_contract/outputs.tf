output "environment_name" {
  value = local.environment_name
}

output "is_prod" {
  value = local.is_prod
}

output "runtime_mode_is_single" {
  value = local.runtime_mode_is_single
}

output "runtime_mode_is_micro" {
  value = local.runtime_mode_is_micro
}

output "backend_ingress_is_vpc_origin" {
  value = local.backend_ingress_is_vpc_origin
}

output "backend_ingress_is_public" {
  value = local.backend_ingress_is_public
}

output "frontend_runtime_is_s3" {
  value = local.frontend_runtime_is_s3
}

output "account_security_controls_enabled" {
  value = local.account_security_controls_enabled
}

output "cost_optimized_dev_tier_enabled" {
  value = local.cost_optimized_dev_tier_enabled
}

output "effective_enable_security_baseline" {
  value = local.effective_enable_security_baseline
}

output "effective_enable_aws_config" {
  value = local.effective_enable_aws_config
}

output "effective_enable_aws_backup" {
  value = local.effective_enable_aws_backup
}

output "effective_enable_inspector" {
  value = local.effective_enable_inspector
}

output "effective_private_app_nat_mode" {
  value = local.effective_private_app_nat_mode
}

output "effective_rds_multi_az" {
  value = local.effective_rds_multi_az
}

output "effective_backend_desired_count" {
  value = local.effective_backend_desired_count
}

output "effective_backend_min_count" {
  value = local.effective_backend_min_count
}

output "effective_backend_max_count" {
  value = local.effective_backend_max_count
}

output "ecs_exec_audit_alerting_enabled" {
  value = local.ecs_exec_audit_alerting_enabled
}

output "enable_environment_suffix" {
  value = local.enable_environment_suffix
}

output "environment_domain" {
  value = local.environment_domain
}

output "route53_zone_id_input" {
  value = local.route53_zone_id_input
}

output "route53_zone_strategy" {
  value = local.route53_zone_strategy
}

output "live_validation_dns_label" {
  value = local.live_validation_dns_label
}

output "frontend_aliases" {
  value = local.frontend_aliases
}

output "backend_path_patterns" {
  value = local.backend_path_patterns
}

output "bucket_name_final" {
  value = local.bucket_name_final
}

output "s3_access_logs_bucket_name_final" {
  value = local.s3_access_logs_bucket_name_final
}

output "alb_access_logs_bucket_name_final" {
  value = local.alb_access_logs_bucket_name_final
}

output "alb_access_logs_dr_bucket_name_final" {
  value = local.alb_access_logs_dr_bucket_name_final
}

output "s3_access_logs_dr_bucket_name_final" {
  value = local.s3_access_logs_dr_bucket_name_final
}

output "dr_frontend_bucket_name_final" {
  value = local.dr_frontend_bucket_name_final
}

output "dr_cloudfront_logs_bucket_name_final" {
  value = local.dr_cloudfront_logs_bucket_name_final
}

output "create_primary_s3_kms_key" {
  value = local.create_primary_s3_kms_key
}

output "create_dr_s3_kms_key" {
  value = local.create_dr_s3_kms_key
}

output "effective_s3_force_destroy" {
  value = local.effective_s3_force_destroy
}

output "effective_alb_deletion_protection" {
  value = local.effective_alb_deletion_protection
}

output "backend_ecr_repository_name_final" {
  value = local.backend_ecr_repository_name_final
}

output "allowed_image_registries_final" {
  value = local.allowed_image_registries_final
}

output "backend_image_repository" {
  value = local.backend_image_repository
}

output "microservice_allowed_image_registry_prefixes" {
  value = local.microservice_allowed_image_registry_prefixes
}

output "alb_access_logs_prefix" {
  value = local.alb_access_logs_prefix
}

output "alb_access_logs_path" {
  value = local.alb_access_logs_path
}

output "securityhub_standards_arns" {
  value = local.securityhub_standards_arns
}

output "service_discovery_namespace_name_final" {
  value = local.service_discovery_namespace_name_final
}

output "microservices_cluster_name_final" {
  value = local.microservices_cluster_name_final
}

output "microservices_exec_log_group_name" {
  value = local.microservices_exec_log_group_name
}

output "smtp_host_final" {
  value = local.smtp_host_final
}

output "frontend_primary_bucket_arn_expected" {
  value = local.frontend_primary_bucket_arn_expected
}

output "frontend_dr_bucket_arn_expected" {
  value = local.frontend_dr_bucket_arn_expected
}

output "create_managed_waf_alb" {
  value = local.create_managed_waf_alb
}

output "create_managed_waf_cloudfront" {
  value = local.create_managed_waf_cloudfront
}

output "effective_enable_managed_waf" {
  value = local.effective_enable_managed_waf
}
