locals {
  bucket_name_final                    = local.is_prod ? var.settings.bucket_name : "${var.settings.bucket_name}-${local.environment_name}"
  s3_access_logs_bucket_name_final     = trimspace(var.settings.s3_access_logs_bucket_name) != "" ? trimspace(var.settings.s3_access_logs_bucket_name) : (local.enable_environment_suffix ? "${var.settings.project_name}-s3-access-logs-${local.environment_name}" : "${var.settings.project_name}-s3-access-logs")
  alb_access_logs_bucket_name_final    = "${local.s3_access_logs_bucket_name_final}-alb"
  alb_access_logs_dr_bucket_name_final = "${local.alb_access_logs_bucket_name_final}-dr-${var.settings.dr_region}"
  s3_access_logs_dr_bucket_name_final  = "${local.s3_access_logs_bucket_name_final}-dr-${var.settings.dr_region}"
  dr_frontend_bucket_name_final        = trimspace(var.settings.dr_frontend_bucket_name) != "" ? trimspace(var.settings.dr_frontend_bucket_name) : "${local.bucket_name_final}-dr-${var.settings.dr_region}"
  dr_cloudfront_logs_bucket_name_final = trimspace(var.settings.dr_cloudfront_logs_bucket_name) != "" ? trimspace(var.settings.dr_cloudfront_logs_bucket_name) : (trimspace(var.settings.cloudfront_logs_bucket_name) != "" ? "${trimspace(var.settings.cloudfront_logs_bucket_name)}-dr-${var.settings.dr_region}" : "")
  create_primary_s3_kms_key            = var.settings.s3_kms_key_id == null
  create_dr_s3_kms_key                 = var.settings.dr_s3_kms_key_id == null
  effective_s3_force_destroy           = var.settings.destroy_mode_enabled ? true : var.settings.s3_force_destroy
  effective_alb_deletion_protection    = var.settings.destroy_mode_enabled ? false : var.settings.alb_deletion_protection
  backend_ecr_repository_name_final    = local.enable_environment_suffix ? "${var.settings.backend_ecr_repository_name}-${local.environment_name}" : var.settings.backend_ecr_repository_name

  default_allowed_image_registries = [
    "${var.settings.account_id}.dkr.ecr.${var.settings.aws_region}.amazonaws.com/${local.backend_ecr_repository_name_final}"
  ]
  default_microservice_allowed_image_registry_prefixes = [
    "${var.settings.account_id}.dkr.ecr.${var.settings.aws_region}.amazonaws.com/"
  ]
  allowed_image_registries_final = length(var.settings.allowed_image_registries) > 0 ? [
    for registry in var.settings.allowed_image_registries : trimspace(registry)
    if trimspace(registry) != ""
  ] : local.default_allowed_image_registries
  backend_image_repository = (
    var.settings.backend_container_image != null && trimspace(var.settings.backend_container_image) != ""
  ) ? split("@", trimspace(var.settings.backend_container_image))[0] : null
  microservice_allowed_image_registry_prefixes = length(var.settings.allowed_image_registries) > 0 ? [
    for registry in var.settings.allowed_image_registries : trimspace(registry)
    if trimspace(registry) != ""
  ] : local.default_microservice_allowed_image_registry_prefixes

  alb_access_logs_prefix = trim(trimspace(var.settings.alb_access_logs_prefix), "/")
  alb_access_logs_path   = local.alb_access_logs_prefix != "" ? "${local.alb_access_logs_prefix}/" : ""
}
