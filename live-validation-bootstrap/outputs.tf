locals {
  live_validation_tfvars = {
    for target_id, target in local.targets : target_id => join("\n", [
      format("project_name                    = %s", jsonencode(var.project_name)),
      format("aws_region                      = %s", jsonencode(var.aws_region)),
      "dr_region                       = \"us-west-2\"",
      format("%s                    = null", target.root_variable_name),
      format("environment_domain              = %s", jsonencode(trimsuffix(lower(trimspace(var.environment_domain)), "."))),
      format("route53_zone_id                 = %s", jsonencode(var.route53_zone_id)),
      format("live_validation_dns_label       = %s", jsonencode(target.dns_label)),
      "app_runtime_mode                = \"gateway_microservices\"",
      "backend_ingress_mode            = \"vpc_origin_alb\"",
      "frontend_runtime_mode           = \"s3\"",
      format("allowed_image_registries        = %s", jsonencode(var.validation_allowed_image_registries)),
      "frontend_geo_restriction_type   = \"none\"",
      "frontend_geo_locations          = []",
      "destroy_mode_enabled            = true",
      "rds_deletion_protection         = false",
      "rds_skip_final_snapshot_on_destroy = true",
      "enable_security_baseline        = false",
      "enable_account_security_controls = false",
      "enable_aws_config               = false",
      format("bucket_name                     = %s", jsonencode(target.bucket_name)),
      format("cloudfront_logs_bucket_name     = %s", jsonencode(target.cloudfront_logs_bucket_name)),
      format("acm_cert_frontend               = %s", jsonencode(aws_acm_certificate_validation.frontend[target_id].certificate_arn)),
      format("alb_certificate_arn             = %s", jsonencode(aws_acm_certificate_validation.alb[target_id].certificate_arn)),
      format("origin_auth_header_ssm_parameter_name = %s", jsonencode(aws_ssm_parameter.origin_auth_current[target_id].name)),
      "backend_cache_policy_id         = \"4135ea2d-6df8-44a3-9df3-4b5a84be39ad\"",
      "backend_origin_request_policy_id = \"b689b0a8-53d0-40ab-baf2-68738e2966ac\"",
      "rds_instance_class              = \"db.t4g.micro\"",
      "rds_enable_performance_insights = false",
      "rds_username                    = \"appadmin\"",
      format("availability_zones              = %s", jsonencode(target.availability_zones)),
      format("vpc_cidr                        = %s", jsonencode(target.vpc_cidr)),
      format("public_app_subnet_cidrs         = %s", jsonencode(target.public_app_subnet_cidrs)),
      format("private_app_subnet_cidrs        = %s", jsonencode(target.private_app_subnet_cidrs)),
      format("private_db_subnet_cidrs         = %s", jsonencode(target.private_db_subnet_cidrs)),
      "private_app_nat_mode            = \"required\"",
      "ecs_services = {",
      "  gateway = {",
      format("    image                    = %s", jsonencode(var.validation_backend_image)),
      "    container_port           = 80",
      "    public                   = true",
      "    desired_count            = 1",
      "    min_count                = 1",
      "    max_count                = 1",
      "    health_check_path        = \"/\"",
      "    readonly_root_fs         = false",
      "    enable_service_discovery = false",
      "  }",
      "}"
    ])
  }
}

output "live_validation_frontend_domains" {
  description = "Frontend validation domains per target."
  value = {
    for target_id, target in local.targets :
    target_id => target.frontend_domain
  }
}

output "live_validation_origin_auth_parameter_names" {
  description = "Origin-auth SecureString parameter names per target."
  value = {
    for target_id, parameter in aws_ssm_parameter.origin_auth_current :
    target_id => parameter.name
  }
}

output "live_validation_frontend_certificate_arns" {
  description = "Validated us-east-1 frontend ACM certificate ARNs per target."
  value = {
    for target_id, validation in aws_acm_certificate_validation.frontend :
    target_id => validation.certificate_arn
  }
}

output "live_validation_alb_certificate_arns" {
  description = "Validated regional ALB ACM certificate ARNs per target."
  value = {
    for target_id, validation in aws_acm_certificate_validation.alb :
    target_id => validation.certificate_arn
  }
}

output "live_validation_tfvars_prod_app" {
  description = "Exact tfvars payload for the LIVE_VALIDATION_TFVARS_PROD_APP GitHub secret."
  value       = local.live_validation_tfvars["prod-app"]
  sensitive   = true
}

output "live_validation_tfvars_nonprod_app" {
  description = "Exact tfvars payload for the LIVE_VALIDATION_TFVARS_NONPROD_APP GitHub secret."
  value       = local.live_validation_tfvars["nonprod-app"]
  sensitive   = true
}
