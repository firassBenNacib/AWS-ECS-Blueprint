output "route53_zone_id_effective" {
  value = local.route53_zone_id_effective
}

output "route53_zone_name_effective" {
  value = local.route53_zone_name_effective
}

output "route53_zone_managed" {
  value = local.route53_zone_managed
}

output "origin_auth_header_value_resolved" {
  value     = var.origin_auth.enabled ? nonsensitive(data.aws_ssm_parameter.origin_auth_header_value[0].value) : ""
  sensitive = true
}

output "origin_auth_previous_header_value_resolved" {
  value = (
    var.origin_auth.enabled && length(data.aws_ssm_parameter.origin_auth_previous_header_value) > 0
    ? nonsensitive(data.aws_ssm_parameter.origin_auth_previous_header_value[0].value)
    : ""
  )
  sensitive = true
}

output "s3_primary_kms_key_arn" {
  value = var.kms.s3_kms_key_id != null ? var.kms.s3_kms_key_id : aws_kms_key.s3_primary[0].arn
}

output "s3_dr_kms_key_arn" {
  value = var.kms.dr_s3_kms_key_id != null ? var.kms.dr_s3_kms_key_id : aws_kms_key.s3_dr[0].arn
}

output "ecs_exec_kms_key_arn_final" {
  value = var.kms.enable_ecs_exec ? aws_kms_key.ecs_exec[0].arn : null
}
