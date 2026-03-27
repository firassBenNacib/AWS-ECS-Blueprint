locals {
  prod_role_arn_effective = (
    var.prod_app_role_arn != null && trimspace(var.prod_app_role_arn) != ""
  ) ? trimspace(var.prod_app_role_arn) : null

  prod_us_east_1_role_arn_effective = (
    var.us_east_1_role_arn != null && trimspace(var.us_east_1_role_arn) != ""
  ) ? trimspace(var.us_east_1_role_arn) : local.prod_role_arn_effective

  prod_dr_role_arn_effective = (
    var.dr_role_arn != null && trimspace(var.dr_role_arn) != ""
  ) ? trimspace(var.dr_role_arn) : local.prod_role_arn_effective

  contract_tags = merge(
    { Deployment = "prod-app" },
    var.org_id != null && trimspace(var.org_id) != "" ? { OrgId = trimspace(var.org_id) } : {},
    var.security_account_id != null && trimspace(var.security_account_id) != "" ? { SecurityAccountId = trimspace(var.security_account_id) } : {},
    var.log_archive_account_id != null && trimspace(var.log_archive_account_id) != "" ? { LogArchiveAccountId = trimspace(var.log_archive_account_id) } : {},
    var.prod_account_id != null && trimspace(var.prod_account_id) != "" ? { ProdAccountId = trimspace(var.prod_account_id) } : {}
  )
}

module "app" {
  source = "../modules/application_platform"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    aws.dr        = aws.dr
  }

  aws_region = var.aws_region
  dr_region  = var.dr_region

  environment_name_override = var.live_validation_mode ? null : "prod"
  enable_environment_suffix = true
  project_name              = var.project_name
  resource_contract_tags    = local.contract_tags

  environment_domain                                         = var.environment_domain
  route53_zone_id                                            = var.route53_zone_id
  route53_zone_strategy                                      = var.route53_zone_strategy
  bucket_name                                                = var.bucket_name
  app_runtime_mode                                           = var.app_runtime_mode
  backend_ingress_mode                                       = var.backend_ingress_mode
  live_validation_mode                                       = var.live_validation_mode
  live_validation_dns_label                                  = var.live_validation_dns_label
  frontend_runtime_mode                                      = var.frontend_runtime_mode
  backend_container_image                                    = var.backend_container_image
  allowed_image_registries                                   = var.allowed_image_registries
  service_discovery_namespace_name                           = var.service_discovery_namespace_name
  ecs_services                                               = var.ecs_services
  frontend_geo_restriction_type                              = var.frontend_geo_restriction_type
  frontend_geo_locations                                     = var.frontend_geo_locations
  acm_cert_frontend                                          = var.acm_cert_frontend
  alb_certificate_arn                                        = var.alb_certificate_arn
  backend_cache_policy_id                                    = var.backend_cache_policy_id
  backend_origin_request_policy_id                           = var.backend_origin_request_policy_id
  availability_zones                                         = var.availability_zones
  vpc_cidr                                                   = var.vpc_cidr
  public_app_subnet_cidrs                                    = var.public_app_subnet_cidrs
  private_app_subnet_cidrs                                   = var.private_app_subnet_cidrs
  private_db_subnet_cidrs                                    = var.private_db_subnet_cidrs
  private_app_nat_mode                                       = var.private_app_nat_mode
  enable_cost_optimized_dev_tier                             = var.enable_cost_optimized_dev_tier
  backend_origin_protocol_policy                             = var.backend_origin_protocol_policy
  origin_auth_header_ssm_parameter_name                      = var.origin_auth_header_ssm_parameter_name
  cloudfront_logs_bucket_name                                = var.cloudfront_logs_bucket_name
  rds_instance_class                                         = var.rds_instance_class
  rds_engine_version                                         = var.rds_engine_version
  rds_multi_az                                               = var.rds_multi_az
  rds_enable_performance_insights                            = var.rds_enable_performance_insights
  enable_rds_master_user_password_rotation                   = var.enable_rds_master_user_password_rotation
  rds_master_user_password_rotation_automatically_after_days = var.rds_master_user_password_rotation_automatically_after_days
  rds_deletion_protection                                    = var.rds_deletion_protection
  rds_skip_final_snapshot_on_destroy                         = var.rds_skip_final_snapshot_on_destroy
  rds_username                                               = var.rds_username
  enable_managed_waf                                         = var.enable_managed_waf
  enable_aws_backup                                          = var.enable_aws_backup
  enable_budget_alerts                                       = var.enable_budget_alerts
  enable_operational_alarms                                  = var.enable_operational_alarms
  enable_security_baseline                                   = var.enable_security_baseline
  enable_account_security_controls                           = var.enable_account_security_controls
  budget_alert_email_addresses                               = var.budget_alert_email_addresses
  budget_alert_topic_arns                                    = var.budget_alert_topic_arns
  budget_alert_threshold_percentages                         = var.budget_alert_threshold_percentages
  budget_total_monthly_limit                                 = var.budget_total_monthly_limit
  budget_cloudfront_monthly_limit                            = var.budget_cloudfront_monthly_limit
  budget_vpc_monthly_limit                                   = var.budget_vpc_monthly_limit
  budget_rds_monthly_limit                                   = var.budget_rds_monthly_limit
  operational_alarm_topic_arn                                = var.operational_alarm_topic_arn
  operational_alarm_alb_target_5xx_threshold                 = var.operational_alarm_alb_target_5xx_threshold
  operational_alarm_ecs_running_task_min_threshold           = var.operational_alarm_ecs_running_task_min_threshold
  operational_alarm_rds_cpu_threshold                        = var.operational_alarm_rds_cpu_threshold
  operational_alarm_cloudfront_5xx_rate_threshold            = var.operational_alarm_cloudfront_5xx_rate_threshold
  security_baseline_enable_object_lock                       = var.security_baseline_enable_object_lock
  enable_aws_config                                          = var.enable_aws_config
  ecs_exec_log_retention_days                                = var.ecs_exec_log_retention_days
  enable_ecs_exec_audit_alerts                               = var.enable_ecs_exec_audit_alerts
  destroy_mode_enabled                                       = var.destroy_mode_enabled
}
