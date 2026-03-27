locals {
  environment_name = (
    var.settings.environment_name_override != null && trimspace(var.settings.environment_name_override) != ""
  ) ? trimspace(var.settings.environment_name_override) : var.workspace_name

  is_prod                                    = local.environment_name == "prod"
  runtime_mode_is_single                     = var.settings.app_runtime_mode == "single_backend"
  runtime_mode_is_micro                      = var.settings.app_runtime_mode == "gateway_microservices"
  backend_ingress_is_vpc_origin              = var.settings.backend_ingress_mode == "vpc_origin_alb"
  backend_ingress_is_public                  = var.settings.backend_ingress_mode == "public_alb_restricted"
  frontend_runtime_is_s3                     = var.settings.frontend_runtime_mode == "s3"
  cost_optimized_dev_tier_enabled            = var.settings.enable_cost_optimized_dev_tier
  effective_enable_security_baseline         = local.cost_optimized_dev_tier_enabled ? false : var.settings.enable_security_baseline
  effective_enable_account_security_controls = local.cost_optimized_dev_tier_enabled ? false : var.settings.enable_account_security_controls
  effective_enable_aws_config                = local.cost_optimized_dev_tier_enabled ? false : var.settings.enable_aws_config
  effective_enable_aws_backup                = local.cost_optimized_dev_tier_enabled ? false : var.settings.enable_aws_backup
  effective_enable_inspector                 = local.cost_optimized_dev_tier_enabled ? false : var.settings.enable_inspector
  effective_private_app_nat_mode             = local.cost_optimized_dev_tier_enabled ? "disabled" : var.settings.private_app_nat_mode
  effective_rds_multi_az                     = local.cost_optimized_dev_tier_enabled ? false : var.settings.rds_multi_az
  effective_backend_desired_count            = local.cost_optimized_dev_tier_enabled ? 1 : var.settings.backend_desired_count
  effective_backend_min_count                = local.cost_optimized_dev_tier_enabled ? 1 : var.settings.backend_min_count
  effective_backend_max_count                = local.cost_optimized_dev_tier_enabled ? 1 : var.settings.backend_max_count
  account_security_controls_enabled          = local.effective_enable_security_baseline && local.effective_enable_account_security_controls
  ecs_exec_audit_alerting_enabled            = local.is_prod && local.account_security_controls_enabled && var.settings.enable_ecs_exec_audit_alerts

  enable_environment_suffix = var.settings.enable_environment_suffix
  environment_domain        = trimsuffix(lower(trimspace(var.settings.environment_domain)), ".")
  route53_zone_id_input = (
    var.settings.route53_zone_id != null && trimspace(var.settings.route53_zone_id) != ""
  ) ? trimspace(var.settings.route53_zone_id) : null
  route53_zone_strategy = lower(trimspace(var.settings.route53_zone_strategy))
  live_validation_dns_label = (
    var.settings.live_validation_dns_label != null && trimspace(var.settings.live_validation_dns_label) != ""
  ) ? trimsuffix(lower(trimspace(var.settings.live_validation_dns_label)), ".") : null

  frontend_aliases = local.is_prod ? [local.environment_domain, "www.${local.environment_domain}"] : (
    var.settings.live_validation_mode
    ? ["${local.live_validation_dns_label}.${local.environment_domain}"]
    : ["${local.environment_name}.${local.environment_domain}", "www.${local.environment_name}.${local.environment_domain}"]
  )
  backend_path_patterns = ["/api/*", "/auth/*", "/audit/*", "/gateway/*", "/notify/twilio/status"]

  service_discovery_namespace_name_final = (
    var.settings.service_discovery_namespace_name != null && trimspace(var.settings.service_discovery_namespace_name) != ""
  ) ? trimsuffix(lower(trimspace(var.settings.service_discovery_namespace_name)), ".") : "${local.environment_name}.${var.settings.project_name}.internal"
  microservices_cluster_name_final  = "${var.settings.project_name}-${local.environment_name}-services"
  microservices_exec_log_group_name = "/aws/ecs/exec/${var.settings.project_name}-${local.environment_name}-services"
  smtp_host_final                   = "email-smtp.${var.settings.aws_region}.amazonaws.com"
}
