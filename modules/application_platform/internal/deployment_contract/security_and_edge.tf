locals {
  securityhub_default_standards_arns = [
    "arn:${var.settings.partition}:securityhub:${var.settings.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0",
    "arn:${var.settings.partition}:securityhub:${var.settings.aws_region}::standards/cis-aws-foundations-benchmark/v/5.0.0"
  ]
  securityhub_standards_arns           = length(var.settings.securityhub_standards_arns) > 0 ? var.settings.securityhub_standards_arns : local.securityhub_default_standards_arns
  frontend_primary_bucket_arn_expected = local.frontend_runtime_is_s3 ? "arn:${var.settings.partition}:s3:::${local.bucket_name_final}" : null
  frontend_dr_bucket_arn_expected      = local.frontend_runtime_is_s3 ? "arn:${var.settings.partition}:s3:::${local.dr_frontend_bucket_name_final}" : null
  effective_enable_managed_waf         = local.cost_optimized_dev_tier_enabled ? false : var.settings.enable_managed_waf
  create_managed_waf_alb               = local.effective_enable_managed_waf && var.settings.alb_web_acl_arn == null
  create_managed_waf_cloudfront        = local.effective_enable_managed_waf && var.settings.frontend_web_acl_arn == null && var.settings.backend_web_acl_arn == null
}
