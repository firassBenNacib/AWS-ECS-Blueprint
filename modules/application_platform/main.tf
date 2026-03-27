data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
module "deployment_contract" {
  source = "./internal/deployment_contract"

  workspace_name = terraform.workspace
  settings = {
    environment_name_override        = var.environment_name_override
    app_runtime_mode                 = var.app_runtime_mode
    backend_ingress_mode             = var.backend_ingress_mode
    frontend_runtime_mode            = var.frontend_runtime_mode
    enable_cost_optimized_dev_tier   = var.enable_cost_optimized_dev_tier
    enable_security_baseline         = var.enable_security_baseline
    enable_account_security_controls = var.enable_account_security_controls
    enable_aws_config                = var.enable_aws_config
    enable_aws_backup                = var.enable_aws_backup
    enable_inspector                 = var.enable_inspector
    enable_ecs_exec_audit_alerts     = var.enable_ecs_exec_audit_alerts
    enable_environment_suffix        = var.enable_environment_suffix
    environment_domain               = var.environment_domain
    route53_zone_id                  = var.route53_zone_id
    route53_zone_strategy            = var.route53_zone_strategy
    live_validation_dns_label        = var.live_validation_dns_label
    live_validation_mode             = var.live_validation_mode
    backend_path_patterns            = var.backend_path_patterns
    bucket_name                      = var.bucket_name
    s3_access_logs_bucket_name       = var.s3_access_logs_bucket_name
    cloudfront_logs_bucket_name      = var.cloudfront_logs_bucket_name
    dr_frontend_bucket_name          = var.dr_frontend_bucket_name
    dr_cloudfront_logs_bucket_name   = var.dr_cloudfront_logs_bucket_name
    s3_kms_key_id                    = var.s3_kms_key_id
    dr_s3_kms_key_id                 = var.dr_s3_kms_key_id
    destroy_mode_enabled             = var.destroy_mode_enabled
    s3_force_destroy                 = var.s3_force_destroy
    alb_deletion_protection          = var.alb_deletion_protection
    backend_ecr_repository_name      = var.backend_ecr_repository_name
    project_name                     = var.project_name
    account_id                       = data.aws_caller_identity.current.account_id
    partition                        = data.aws_partition.current.partition
    aws_region                       = var.aws_region
    dr_region                        = var.dr_region
    private_app_nat_mode             = var.private_app_nat_mode
    rds_multi_az                     = var.rds_multi_az
    backend_desired_count            = var.backend_desired_count
    backend_min_count                = var.backend_min_count
    backend_max_count                = var.backend_max_count
    securityhub_standards_arns       = var.securityhub_standards_arns
    allowed_image_registries         = var.allowed_image_registries
    backend_container_image          = var.backend_container_image
    service_discovery_namespace_name = var.service_discovery_namespace_name
    alb_access_logs_prefix           = var.alb_access_logs_prefix
    enable_managed_waf               = var.enable_managed_waf
    alb_web_acl_arn                  = var.alb_web_acl_arn
    frontend_web_acl_arn             = var.frontend_web_acl_arn
    backend_web_acl_arn              = var.backend_web_acl_arn
  }
}

module "platform_core" {
  source = "./internal/platform_core"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  environment = {
    name                  = module.deployment_contract.environment_name
    domain                = module.deployment_contract.environment_domain
    route53_zone_id_input = module.deployment_contract.route53_zone_id_input
    route53_zone_strategy = module.deployment_contract.route53_zone_strategy
    live_validation_mode  = var.live_validation_mode
    live_validation_label = module.deployment_contract.live_validation_dns_label
  }

  origin_auth = {
    enabled                     = var.enable_origin_auth_header
    header_ssm_parameter_name   = var.origin_auth_header_ssm_parameter_name
    previous_ssm_parameter_name = var.origin_auth_previous_header_ssm_parameter_name
  }

  kms = {
    project_name              = var.project_name
    aws_region                = var.aws_region
    dr_region                 = var.dr_region
    create_primary_s3_kms_key = module.deployment_contract.create_primary_s3_kms_key
    create_dr_s3_kms_key      = module.deployment_contract.create_dr_s3_kms_key
    s3_kms_key_id             = var.s3_kms_key_id
    dr_s3_kms_key_id          = var.dr_s3_kms_key_id
    enable_ecs_exec           = var.enable_ecs_exec
  }

  guardrails = {
    availability_zones                           = var.availability_zones
    public_app_subnet_cidrs                      = var.public_app_subnet_cidrs
    private_app_subnet_cidrs                     = var.private_app_subnet_cidrs
    private_db_subnet_cidrs                      = var.private_db_subnet_cidrs
    destroy_mode_enabled                         = var.destroy_mode_enabled
    effective_alb_deletion_protection            = module.deployment_contract.effective_alb_deletion_protection
    origin_auth_header_name                      = var.origin_auth_header_name
    origin_auth_previous_header_name             = var.origin_auth_previous_header_name
    enable_cloudfront_access_logs                = var.enable_cloudfront_access_logs
    cloudfront_logs_bucket_name                  = var.cloudfront_logs_bucket_name
    effective_s3_force_destroy                   = module.deployment_contract.effective_s3_force_destroy
    s3_versioning_enabled                        = var.s3_versioning_enabled
    enable_managed_waf                           = module.deployment_contract.effective_enable_managed_waf
    alb_web_acl_arn                              = var.alb_web_acl_arn
    frontend_web_acl_arn                         = var.frontend_web_acl_arn
    backend_web_acl_arn                          = var.backend_web_acl_arn
    interface_endpoint_services                  = var.interface_endpoint_services
    account_security_controls_enabled            = module.deployment_contract.account_security_controls_enabled
    securityhub_standards_arns                   = module.deployment_contract.securityhub_standards_arns
    selected_interface_endpoints_sg_id           = module.networking.interface_endpoints_sg_id
    selected_s3_gateway_prefix_list_id           = module.networking.s3_gateway_prefix_list_id
    runtime_mode_is_micro                        = module.deployment_contract.runtime_mode_is_micro
    ecs_services_final                           = module.policy_assembly.ecs_services_final
    public_service_keys                          = module.policy_assembly.public_service_keys
    microservice_image_repositories              = module.policy_assembly.microservice_image_repositories
    microservice_allowed_image_registry_prefixes = module.deployment_contract.microservice_allowed_image_registry_prefixes
    runtime_mode_is_single                       = module.deployment_contract.runtime_mode_is_single
    create_backend_ecr_repository                = var.create_backend_ecr_repository
    allowed_image_registries_final               = module.deployment_contract.allowed_image_registries_final
    backend_image_repository                     = module.deployment_contract.backend_image_repository
    backend_min_count                            = module.deployment_contract.effective_backend_min_count
    backend_desired_count                        = module.deployment_contract.effective_backend_desired_count
    backend_max_count                            = module.deployment_contract.effective_backend_max_count
    ecs_exec_log_group_name                      = var.ecs_exec_log_group_name
    enable_cloudtrail_data_events                = var.enable_cloudtrail_data_events
    cloudtrail_data_event_resources              = var.cloudtrail_data_event_resources
    cost_optimized_dev_tier_enabled              = module.deployment_contract.cost_optimized_dev_tier_enabled
  }
}
module "access_log_storage" {
  source = "./internal/access_log_storage"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  environment = {
    name          = module.deployment_contract.environment_name
    enable_suffix = module.deployment_contract.enable_environment_suffix
  }

  buckets = {
    s3_access_logs_bucket_name     = module.deployment_contract.s3_access_logs_bucket_name_final
    s3_access_logs_dr_bucket_name  = module.deployment_contract.s3_access_logs_dr_bucket_name_final
    alb_access_logs_bucket_name    = module.deployment_contract.alb_access_logs_bucket_name_final
    alb_access_logs_dr_bucket_name = module.deployment_contract.alb_access_logs_dr_bucket_name_final
    cloudfront_logs_bucket_name    = var.cloudfront_logs_bucket_name
    cloudfront_logs_dr_bucket_name = module.deployment_contract.dr_cloudfront_logs_bucket_name_final
    force_destroy                  = module.deployment_contract.effective_s3_force_destroy
  }

  kms = {
    s3_primary_kms_key_arn = module.platform_core.s3_primary_kms_key_arn
    s3_dr_kms_key_arn      = module.platform_core.s3_dr_kms_key_arn
  }

  logging = {
    enable_s3_access_logging                               = var.enable_s3_access_logging
    alb_access_logs_path                                   = module.deployment_contract.alb_access_logs_path
    enable_cloudfront_logs_lifecycle                       = var.enable_cloudfront_logs_lifecycle
    cloudfront_logs_expiration_days                        = var.cloudfront_logs_expiration_days
    cloudfront_logs_abort_incomplete_multipart_upload_days = var.cloudfront_logs_abort_incomplete_multipart_upload_days
  }

  source_arns = {
    frontend_primary_bucket_arn = module.deployment_contract.frontend_primary_bucket_arn_expected
    frontend_dr_bucket_arn      = module.deployment_contract.frontend_dr_bucket_arn_expected
  }
}

module "networking" {
  source = "./internal/networking"

  environment = {
    name          = module.deployment_contract.environment_name
    enable_suffix = module.deployment_contract.enable_environment_suffix
  }

  network = {
    vpc_name                        = var.vpc_name
    vpc_cidr                        = var.vpc_cidr
    availability_zones              = var.availability_zones
    public_app_subnet_cidrs         = var.public_app_subnet_cidrs
    private_app_subnet_cidrs        = var.private_app_subnet_cidrs
    private_db_subnet_cidrs         = var.private_db_subnet_cidrs
    flow_logs_retention_days        = var.vpc_flow_logs_retention_days
    flow_logs_kms_key_id            = var.vpc_flow_logs_kms_key_id
    flow_logs_name_prefix           = "${var.vpc_name}-${module.deployment_contract.environment_name}"
    lockdown_default_security_group = var.lockdown_default_security_group
    interface_endpoint_services     = var.interface_endpoint_services
    private_app_nat_mode            = module.deployment_contract.effective_private_app_nat_mode
  }

  security = {
    runtime_mode_is_single         = module.deployment_contract.runtime_mode_is_single
    runtime_mode_is_micro          = module.deployment_contract.runtime_mode_is_micro
    backend_container_port         = var.backend_container_port
    alb_listener_port              = var.alb_listener_port
    backend_origin_protocol_policy = var.backend_origin_protocol_policy
    vpc_cidr                       = var.vpc_cidr
    public_service_port            = module.policy_assembly.public_service_port
    ecs_services_final             = var.ecs_services
  }
}

module "backend_edge" {
  source = "./internal/backend_edge"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  environment = {
    name          = module.deployment_contract.environment_name
    enable_suffix = module.deployment_contract.enable_environment_suffix
  }

  ingress = {
    selected_vpc_id                     = module.networking.vpc_id
    selected_alb_subnet_ids             = module.edge_contract.selected_alb_subnet_ids
    backend_ingress_is_vpc_origin       = module.deployment_contract.backend_ingress_is_vpc_origin
    backend_ingress_is_public           = module.deployment_contract.backend_ingress_is_public
    runtime_mode_is_micro               = module.deployment_contract.runtime_mode_is_micro
    alb_security_group_id               = module.networking.backend_alb_security_group_id
    microservices_alb_security_group_id = coalesce(module.networking.microservices_alb_security_group_id, module.networking.backend_alb_security_group_id)
    alb_app_port                        = module.deployment_contract.runtime_mode_is_single ? var.backend_container_port : module.policy_assembly.public_service_port
    alb_health_check_path               = module.deployment_contract.runtime_mode_is_single ? var.backend_healthcheck_path : module.policy_assembly.public_service_health_check_path
    alb_listener_port                   = var.alb_listener_port
    backend_origin_protocol_policy      = var.backend_origin_protocol_policy
    origin_auth_enabled                 = var.enable_origin_auth_header
    origin_auth_header_name             = var.origin_auth_header_name
    origin_auth_header_value            = module.platform_core.origin_auth_header_value_resolved
    origin_auth_previous_header_name    = var.origin_auth_previous_header_name
    origin_auth_previous_header_value   = module.platform_core.origin_auth_previous_header_value_resolved
  }

  alb_config = {
    certificate_arn                  = var.alb_certificate_arn
    ssl_policy                       = var.alb_ssl_policy
    health_check_matcher             = var.alb_health_check_matcher
    health_check_interval_seconds    = var.alb_health_check_interval_seconds
    health_check_timeout_seconds     = var.alb_health_check_timeout_seconds
    health_check_healthy_threshold   = var.alb_health_check_healthy_threshold
    health_check_unhealthy_threshold = var.alb_health_check_unhealthy_threshold
    alb_name                         = var.alb_name
    target_group_name                = var.alb_target_group_name
    deletion_protection              = module.deployment_contract.effective_alb_deletion_protection
    idle_timeout                     = var.alb_idle_timeout
    access_logs_bucket               = module.access_log_storage.alb_access_logs_bucket_id
    access_logs_prefix               = module.deployment_contract.alb_access_logs_prefix
  }

  waf_config = {
    create_managed_alb        = module.deployment_contract.create_managed_waf_alb
    create_managed_cloudfront = module.deployment_contract.create_managed_waf_cloudfront
    rate_limit_requests       = var.waf_rate_limit_requests_per_5_mins
    log_retention_days        = var.waf_log_retention_days
    alb_web_acl_arn           = var.alb_web_acl_arn
    frontend_web_acl_arn      = var.frontend_web_acl_arn
    backend_web_acl_arn       = var.backend_web_acl_arn
  }
}

module "frontend_storage" {
  source = "./internal/frontend_storage"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  environment = {
    name          = module.deployment_contract.environment_name
    enable_suffix = module.deployment_contract.enable_environment_suffix
  }

  frontend = {
    runtime_is_s3                                    = module.deployment_contract.frontend_runtime_is_s3
    bucket_name                                      = module.deployment_contract.bucket_name_final
    dr_bucket_name                                   = module.deployment_contract.dr_frontend_bucket_name_final
    force_destroy                                    = module.deployment_contract.effective_s3_force_destroy
    versioning_enabled                               = var.s3_versioning_enabled
    enable_kms_encryption                            = true
    primary_kms_key_arn                              = module.platform_core.s3_primary_kms_key_arn
    dr_kms_key_arn                                   = module.platform_core.s3_dr_kms_key_arn
    enable_access_logging                            = var.enable_s3_access_logging
    primary_access_logging_target_bucket_name        = module.access_log_storage.s3_access_logs_bucket_id
    primary_access_logging_prerequisite_id           = module.access_log_storage.s3_access_logs_bucket_policy_id
    primary_access_logging_target_prefix             = "s3-access/frontend/"
    dr_access_logging_target_bucket_name             = module.access_log_storage.s3_access_logs_dr_bucket_id
    dr_access_logging_prerequisite_id                = module.access_log_storage.s3_access_logs_dr_bucket_policy_id
    enable_lifecycle                                 = var.enable_s3_lifecycle
    lifecycle_expiration_days                        = var.s3_lifecycle_expiration_days
    lifecycle_noncurrent_expiration_days             = var.s3_lifecycle_noncurrent_expiration_days
    lifecycle_abort_incomplete_multipart_upload_days = var.s3_lifecycle_abort_incomplete_multipart_upload_days
  }
}

module "edge_contract" {
  source = "./internal/edge_contract"

  routing = {
    frontend_aliases              = module.deployment_contract.frontend_aliases
    backend_path_patterns         = module.deployment_contract.backend_path_patterns
    backend_ingress_is_vpc_origin = module.deployment_contract.backend_ingress_is_vpc_origin
    route53_zone_id_effective     = module.platform_core.route53_zone_id_effective
    route53_zone_name_effective   = module.platform_core.route53_zone_name_effective
    route53_zone_managed          = module.platform_core.route53_zone_managed
    frontend_runtime_is_s3        = module.deployment_contract.frontend_runtime_is_s3
    bucket_name_final             = module.deployment_contract.bucket_name_final
    dr_frontend_bucket_name_final = module.deployment_contract.dr_frontend_bucket_name_final
    create_managed_waf_alb        = module.deployment_contract.create_managed_waf_alb
    create_managed_waf_cloudfront = module.deployment_contract.create_managed_waf_cloudfront
  }

  networking = {
    vpc_id                    = module.networking.vpc_id
    interface_endpoints_sg_id = module.networking.interface_endpoints_sg_id
    s3_gateway_prefix_list_id = module.networking.s3_gateway_prefix_list_id
    public_edge_subnet_ids    = module.networking.public_edge_subnet_ids
    private_app_subnet_ids    = module.networking.private_app_subnet_ids
    private_db_subnet_ids     = module.networking.private_db_subnet_ids
  }

  frontend = {
    primary_bucket_name    = module.frontend_storage.frontend_primary_bucket_name
    primary_bucket_domain  = module.frontend_storage.frontend_primary_bucket_domain
    primary_bucket_arn     = module.frontend_storage.frontend_primary_bucket_arn
    dr_bucket_name         = module.frontend_storage.frontend_dr_bucket_name
    dr_bucket_domain       = module.frontend_storage.frontend_dr_bucket_domain
    dr_bucket_arn          = module.frontend_storage.frontend_dr_bucket_arn
    cloudfront_logs_domain = module.access_log_storage.cloudfront_logs_bucket_domain
  }
}

module "frontend_edge" {
  source = "./internal/frontend_edge"

  environment = {
    name          = module.deployment_contract.environment_name
    enable_suffix = module.deployment_contract.enable_environment_suffix
    domain        = module.deployment_contract.environment_domain
    project_name  = var.project_name
  }

  frontend = {
    bucket_domain           = module.edge_contract.frontend_primary_bucket_domain
    secondary_bucket_domain = module.edge_contract.dr_frontend_bucket_domain
    aliases                 = module.edge_contract.frontend_aliases
    cert_arn                = var.acm_cert_frontend
    cache_policy_id         = var.frontend_cache_policy_id
    price_class             = var.frontend_price_class
    viewer_protocol_policy  = var.frontend_viewer_protocol_policy
    geo_restriction_type    = var.frontend_geo_restriction_type
    geo_locations           = var.frontend_geo_locations
    access_logs_bucket      = module.edge_contract.cloudfront_logs_bucket_domain
    access_logs_prefix      = "${var.cloudfront_logs_prefix}edge/"
    runtime_mode            = var.frontend_runtime_mode
    alb_domain_name         = module.backend_edge.alb_dns_name
    vpc_origin_id           = module.backend_edge.backend_vpc_origin_id_final
    alb_https_port          = var.alb_listener_port
  }

  backend = {
    origin_enabled                    = true
    origin_domain_name                = module.backend_edge.alb_dns_name
    origin_vpc_origin_id              = module.backend_edge.backend_vpc_origin_id_final
    origin_https_port                 = var.alb_listener_port
    origin_protocol_policy            = var.backend_origin_protocol_policy
    viewer_protocol_policy            = var.backend_viewer_protocol_policy
    cache_policy_id                   = var.backend_cache_policy_id
    origin_request_policy_id          = var.backend_origin_request_policy_id
    allowed_methods                   = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    path_patterns                     = module.edge_contract.backend_path_patterns
    origin_auth_enabled               = var.enable_origin_auth_header
    origin_auth_header_name           = var.origin_auth_header_name
    origin_auth_header_value          = module.platform_core.origin_auth_header_value_resolved
    origin_auth_previous_header_name  = var.origin_auth_previous_header_name
    origin_auth_previous_header_value = module.platform_core.origin_auth_previous_header_value_resolved
  }

  route53_zone_id_effective = module.edge_contract.route53_zone_id_effective
  web_acl_id = (
    var.frontend_web_acl_arn != null ? var.frontend_web_acl_arn : (
      var.backend_web_acl_arn != null ? var.backend_web_acl_arn : module.backend_edge.cloudfront_web_acl_arn
    )
  )
}

module "frontend_origin_access" {
  source = "./internal/frontend_origin_access"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  frontend = {
    runtime_is_s3                = module.deployment_contract.frontend_runtime_is_s3
    frontend_primary_bucket_name = module.edge_contract.frontend_primary_bucket_name
    frontend_primary_bucket_arn  = module.edge_contract.frontend_primary_bucket_arn
    frontend_dr_bucket_name      = module.edge_contract.frontend_dr_bucket_name
    frontend_dr_bucket_arn       = module.edge_contract.frontend_dr_bucket_arn
    distribution_arn             = module.frontend_edge.frontend_distribution_arn
  }
}

module "app_data" {
  source = "./internal/app_data"

  environment = {
    name          = module.deployment_contract.environment_name
    enable_suffix = module.deployment_contract.enable_environment_suffix
  }

  data = {
    identifier                                             = var.rds_identifier
    db_name                                                = var.rds_db_name
    username                                               = var.rds_username
    master_user_secret_kms_key_id                          = var.rds_master_user_secret_kms_key_id
    engine_version                                         = var.rds_engine_version
    instance_class                                         = var.rds_instance_class
    multi_az                                               = module.deployment_contract.effective_rds_multi_az
    auto_minor_version_upgrade                             = var.rds_auto_minor_version_upgrade
    allocated_storage                                      = var.rds_allocated_storage
    max_allocated_storage                                  = var.rds_max_allocated_storage
    manage_master_user_password_rotation                   = var.enable_rds_master_user_password_rotation
    master_user_password_rotation_automatically_after_days = var.rds_master_user_password_rotation_automatically_after_days
    backup_retention_period                                = var.rds_backup_retention_period
    preferred_backup_window                                = var.rds_preferred_backup_window
    preferred_maintenance_window                           = var.rds_preferred_maintenance_window
    final_snapshot_identifier                              = var.rds_final_snapshot_identifier
    deletion_protection                                    = var.destroy_mode_enabled ? false : var.rds_deletion_protection
    skip_final_snapshot                                    = var.destroy_mode_enabled ? true : var.rds_skip_final_snapshot_on_destroy
    enable_performance_insights                            = var.rds_enable_performance_insights
    enable_iam_database_auth                               = var.enable_rds_iam_auth
    monitoring_interval_seconds                            = var.rds_monitoring_interval_seconds
    enabled_cloudwatch_logs_exports                        = var.rds_enabled_cloudwatch_logs_exports
    rds_sg_id                                              = module.networking.rds_security_group_id
    db_subnet_ids                                          = module.edge_contract.selected_db_subnet_ids
    rotation_subnet_ids                                    = module.edge_contract.selected_private_app_subnet_ids
    notification_topic_kms_key_arn                         = module.platform_core.s3_primary_kms_key_arn
    rotation_security_group_ids = compact([
      module.deployment_contract.runtime_mode_is_single ? module.networking.backend_service_security_group_id : module.networking.microservices_internal_security_group_id
    ])
  }
}

module "policy_assembly" {
  source = "./internal/policy_assembly"

  runtime = {
    runtime_mode_is_micro           = module.deployment_contract.runtime_mode_is_micro
    cost_optimized_dev_tier_enabled = module.deployment_contract.cost_optimized_dev_tier_enabled
    project_name                    = var.project_name
    environment_name                = module.deployment_contract.environment_name
    aws_region                      = var.aws_region
    rds_db_name                     = var.rds_db_name
    rds_username                    = var.rds_username
  }

  backend = {
    backend_env                     = var.backend_env
    backend_secret_arns             = var.backend_secret_arns
    backend_rds_secret_env_var_name = var.backend_rds_secret_env_var_name
    backend_container_image         = var.backend_container_image
    allowed_image_registries_final  = module.deployment_contract.allowed_image_registries_final
    microservice_allowed_registries = module.deployment_contract.microservice_allowed_image_registry_prefixes
  }

  app_data = {
    address                = module.app_data.address
    master_user_secret_arn = module.app_data.master_user_secret_arn
  }

  ecs_services = var.ecs_services
}

module "platform_governance" {
  source = "./internal/platform_governance"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  security = {
    account_security_controls_enabled   = module.deployment_contract.account_security_controls_enabled
    name_prefix                         = module.deployment_contract.enable_environment_suffix ? "${var.project_name}-${module.deployment_contract.environment_name}" : var.project_name
    log_bucket_name                     = module.deployment_contract.enable_environment_suffix ? lower("${var.project_name}-security-baseline-${data.aws_caller_identity.current.account_id}-${module.deployment_contract.environment_name}") : lower("${var.project_name}-security-baseline-${data.aws_caller_identity.current.account_id}")
    securityhub_standards               = module.deployment_contract.securityhub_standards_arns
    cloudtrail_retention_days           = var.security_baseline_log_retention_days
    access_logs_bucket_name             = module.deployment_contract.s3_access_logs_bucket_name_final
    access_logs_bucket_name_dr          = module.deployment_contract.s3_access_logs_dr_bucket_name_final
    enable_aws_config                   = module.deployment_contract.effective_enable_aws_config
    security_findings_sns_topic_arn     = var.security_findings_sns_topic_arn
    security_findings_sns_subscriptions = var.security_findings_sns_subscriptions
    enable_cloudtrail_data_events       = var.enable_cloudtrail_data_events
    cloudtrail_data_event_resources     = var.cloudtrail_data_event_resources
    enable_inspector                    = module.deployment_contract.effective_enable_inspector
    inspector_resource_types            = var.inspector_resource_types
    enable_ecs_exec_audit_alerts        = module.deployment_contract.ecs_exec_audit_alerting_enabled
    enable_log_bucket_object_lock       = !var.destroy_mode_enabled && var.security_baseline_enable_object_lock
    log_bucket_force_destroy            = module.deployment_contract.effective_s3_force_destroy
  }

  backup = {
    name_prefix                      = module.deployment_contract.enable_environment_suffix ? "${var.project_name}-${module.deployment_contract.environment_name}" : var.project_name
    enable_aws_backup                = module.deployment_contract.effective_enable_aws_backup
    backup_vault_name                = var.aws_backup_vault_name
    backup_schedule_expression       = var.aws_backup_schedule_expression
    backup_retention_days            = var.aws_backup_retention_days
    backup_start_window_minutes      = var.aws_backup_start_window_minutes
    backup_completion_window_minutes = var.aws_backup_completion_window_minutes
    backup_cross_region_copy_enabled = var.aws_backup_cross_region_copy_enabled
    backup_copy_retention_days       = var.aws_backup_copy_retention_days
    rds_instance_arn                 = module.app_data.instance_arn
    frontend_primary_bucket_arn      = module.edge_contract.frontend_primary_bucket_arn
  }

  budget = {
    enable_budget_alerts         = var.enable_budget_alerts
    name_prefix                  = module.deployment_contract.enable_environment_suffix ? "${var.project_name}-${module.deployment_contract.environment_name}" : var.project_name
    notification_email_addresses = var.budget_alert_email_addresses
    notification_topic_arns      = var.budget_alert_topic_arns
    alert_threshold_percentages  = var.budget_alert_threshold_percentages
    total_monthly_limit          = var.budget_total_monthly_limit
    cloudfront_monthly_limit     = var.budget_cloudfront_monthly_limit
    vpc_monthly_limit            = var.budget_vpc_monthly_limit
    rds_monthly_limit            = var.budget_rds_monthly_limit
  }
}

module "app_runtime" {
  source = "./internal/app_runtime"

  environment = {
    name          = module.deployment_contract.environment_name
    enable_suffix = module.deployment_contract.enable_environment_suffix
  }

  runtime = {
    runtime_mode_is_single                         = module.deployment_contract.runtime_mode_is_single
    runtime_mode_is_micro                          = module.deployment_contract.runtime_mode_is_micro
    public_service_key                             = module.policy_assembly.public_service_key
    project_name                                   = var.project_name
    selected_private_app_subnet_ids                = module.edge_contract.selected_private_app_subnet_ids
    selected_vpc_id                                = module.edge_contract.selected_vpc_id
    service_discovery_namespace_name_final         = module.deployment_contract.service_discovery_namespace_name_final
    microservices_cluster_name_final               = module.deployment_contract.microservices_cluster_name_final
    microservices_exec_log_group_name              = module.deployment_contract.microservices_exec_log_group_name
    enable_ecs_exec                                = var.enable_ecs_exec
    ecs_exec_log_retention_days                    = var.ecs_exec_log_retention_days
    ecs_exec_kms_key_arn_final                     = module.platform_core.ecs_exec_kms_key_arn_final
    backend_scale_in_cooldown_seconds              = var.backend_scale_in_cooldown_seconds
    backend_scale_out_cooldown_seconds             = var.backend_scale_out_cooldown_seconds
    backend_deploy_alarm_5xx_threshold             = var.backend_deploy_alarm_5xx_threshold
    backend_deploy_alarm_unhealthy_hosts_threshold = var.backend_deploy_alarm_unhealthy_hosts_threshold
    backend_deploy_alarm_eval_periods              = var.backend_deploy_alarm_eval_periods
  }

  single_backend = {
    create_backend_ecr_repository                = var.create_backend_ecr_repository
    backend_ecr_repository_name_final            = module.deployment_contract.backend_ecr_repository_name_final
    backend_ecr_lifecycle_max_images             = var.backend_ecr_lifecycle_max_images
    backend_ecr_kms_key_arn                      = var.backend_ecr_kms_key_arn
    cluster_name                                 = var.backend_cluster_name
    service_name                                 = var.backend_service_name
    task_family                                  = var.backend_task_family
    execution_role_name                          = var.backend_execution_role_name
    task_role_name                               = var.backend_task_role_name
    container_name                               = var.backend_container_name
    container_image                              = var.backend_container_image
    container_port                               = var.backend_container_port
    container_user                               = var.backend_container_user
    readonly_root_fs                             = var.backend_readonly_root_filesystem
    drop_capabilities                            = var.backend_drop_linux_capabilities
    task_cpu                                     = var.backend_task_cpu
    task_memory                                  = var.backend_task_memory
    task_cpu_architecture                        = var.backend_task_cpu_architecture
    desired_count                                = module.deployment_contract.effective_backend_desired_count
    min_count                                    = module.deployment_contract.effective_backend_min_count
    max_count                                    = module.deployment_contract.effective_backend_max_count
    cpu_target_value                             = var.backend_cpu_target_value
    memory_target_value                          = var.backend_memory_target_value
    alb_request_count_target_value               = var.backend_alb_request_count_target_value
    alb_request_count_scale_in_cooldown_seconds  = var.backend_alb_request_count_scale_in_cooldown_seconds
    alb_request_count_scale_out_cooldown_seconds = var.backend_alb_request_count_scale_out_cooldown_seconds
    health_check_grace_period_seconds            = var.backend_healthcheck_grace_period_seconds
    exec_log_group_name                          = var.ecs_exec_log_group_name
    environment                                  = module.policy_assembly.backend_env_final
    secret_arns                                  = module.policy_assembly.backend_secret_arns_final
    secret_kms_key_arns                          = var.backend_secret_kms_key_arns
    task_role_policy_json                        = var.backend_task_role_policy_json
    log_group_name                               = var.backend_log_group_name
    log_retention_days                           = var.backend_log_retention_days
    log_kms_key_id                               = var.backend_log_kms_key_id
  }

  microservices = {
    ecs_services_final = module.policy_assembly.ecs_services_final
  }

  networking = {
    backend_service_security_group_id             = module.networking.backend_service_security_group_id
    microservices_gateway_security_group_id       = module.networking.microservices_gateway_security_group_id
    microservices_internal_security_group_id      = module.networking.microservices_internal_security_group_id
    microservices_extra_egress_security_group_ids = module.networking.microservices_extra_egress_security_group_ids
  }

  edge = {
    target_group_arn        = module.backend_edge.target_group_arn
    alb_arn_suffix          = module.backend_edge.alb_arn_suffix
    target_group_arn_suffix = module.backend_edge.target_group_arn_suffix
  }
}

module "operational_observability" {
  source = "./internal/operational_observability"

  enabled                    = var.enable_operational_alarms
  name_prefix                = module.deployment_contract.enable_environment_suffix ? "${var.project_name}-${module.deployment_contract.environment_name}" : var.project_name
  notifications_topic_arn    = var.operational_alarm_topic_arn != null ? var.operational_alarm_topic_arn : module.platform_governance.security_findings_sns_topic_arn
  alb_arn_suffix             = module.backend_edge.alb_arn_suffix
  target_group_arn_suffix    = module.backend_edge.target_group_arn_suffix
  ecs_cluster_name           = module.app_runtime.backend_ecs_cluster_name
  ecs_service_name           = module.app_runtime.backend_ecs_service_name
  rds_instance_identifier    = module.app_data.instance_identifier
  cloudfront_distribution_id = module.frontend_edge.frontend_distribution_id

  alb_target_5xx_threshold       = var.operational_alarm_alb_target_5xx_threshold
  ecs_running_task_min_threshold = var.operational_alarm_ecs_running_task_min_threshold
  rds_cpu_threshold              = var.operational_alarm_rds_cpu_threshold
  cloudfront_5xx_rate_threshold  = var.operational_alarm_cloudfront_5xx_rate_threshold
}
