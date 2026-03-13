locals {
  nonprod_role_arn_effective = (
    var.nonprod_app_role_arn != null && trimspace(var.nonprod_app_role_arn) != ""
  ) ? trimspace(var.nonprod_app_role_arn) : null

  nonprod_us_east_1_role_arn_effective = (
    var.us_east_1_role_arn != null && trimspace(var.us_east_1_role_arn) != ""
  ) ? trimspace(var.us_east_1_role_arn) : local.nonprod_role_arn_effective

  nonprod_dr_role_arn_effective = (
    var.dr_role_arn != null && trimspace(var.dr_role_arn) != ""
  ) ? trimspace(var.dr_role_arn) : local.nonprod_role_arn_effective

  contract_tags = merge(
    { Deployment = "nonprod-app" },
    var.org_id != null && trimspace(var.org_id) != "" ? { OrgId = trimspace(var.org_id) } : {},
    var.security_account_id != null && trimspace(var.security_account_id) != "" ? { SecurityAccountId = trimspace(var.security_account_id) } : {},
    var.log_archive_account_id != null && trimspace(var.log_archive_account_id) != "" ? { LogArchiveAccountId = trimspace(var.log_archive_account_id) } : {},
    var.prod_account_id != null && trimspace(var.prod_account_id) != "" ? { ProdAccountId = trimspace(var.prod_account_id) } : {}
  )
}

module "app" {
  source = "../modules/app_stack"

  aws_region = var.aws_region
  dr_region  = var.dr_region

  aws_assume_role_arn          = local.nonprod_role_arn_effective
  us_east_1_assume_role_arn    = local.nonprod_us_east_1_role_arn_effective
  dr_assume_role_arn           = local.nonprod_dr_role_arn_effective
  aws_assume_role_external_id  = var.assume_role_external_id
  aws_assume_role_session_name = "terraform-nonprod-app"
  environment_name_override    = "nonprod"
  enable_environment_suffix    = true
  project_name                 = var.project_name

  environment_domain                    = var.environment_domain
  route53_zone_id                       = var.route53_zone_id
  bucket_name                           = var.bucket_name
  app_runtime_mode                      = var.app_runtime_mode
  frontend_runtime_mode                 = var.frontend_runtime_mode
  backend_container_image               = var.backend_container_image
  service_discovery_namespace_name      = var.service_discovery_namespace_name
  ecs_services                          = var.ecs_services
  backend_geo_restriction_type          = var.backend_geo_restriction_type
  backend_geo_locations                 = var.backend_geo_locations
  frontend_geo_restriction_type         = var.frontend_geo_restriction_type
  frontend_geo_locations                = var.frontend_geo_locations
  acm_cert_frontend                     = var.acm_cert_frontend
  alb_certificate_arn                   = var.alb_certificate_arn
  backend_cache_policy_id               = var.backend_cache_policy_id
  backend_origin_request_policy_id      = var.backend_origin_request_policy_id
  availability_zones                    = var.availability_zones
  vpc_cidr                              = var.vpc_cidr
  public_app_subnet_cidrs               = var.public_app_subnet_cidrs
  private_app_subnet_cidrs              = var.private_app_subnet_cidrs
  private_db_subnet_cidrs               = var.private_db_subnet_cidrs
  private_app_nat_mode                  = var.private_app_nat_mode
  backend_origin_protocol_policy        = var.backend_origin_protocol_policy
  origin_auth_header_ssm_parameter_name = var.origin_auth_header_ssm_parameter_name
  cloudfront_logs_bucket_name           = var.cloudfront_logs_bucket_name
  rds_instance_class                    = var.rds_instance_class
  rds_enable_performance_insights       = var.rds_enable_performance_insights
  rds_deletion_protection               = var.rds_deletion_protection
  rds_skip_final_snapshot_on_destroy    = var.rds_skip_final_snapshot_on_destroy
  rds_username                          = var.rds_username
  enable_security_baseline              = var.enable_security_baseline
  enable_account_security_controls      = var.enable_account_security_controls
  security_baseline_enable_object_lock  = var.security_baseline_enable_object_lock
  enable_aws_config                     = var.enable_aws_config
  destroy_mode_enabled                  = var.destroy_mode_enabled
  backend_failover_domain_name          = var.backend_failover_domain_name

  additional_tags = local.contract_tags
}
