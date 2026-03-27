output "cloudtrail_arn" {
  value = try(module.security_baseline[0].cloudtrail_arn, null)
}

output "log_bucket_name" {
  value = try(module.security_baseline[0].log_bucket_name, null)
}

output "log_bucket_dr_name" {
  value = try(module.security_baseline[0].log_bucket_dr_name, null)
}

output "config_recorder_name" {
  value = try(module.security_baseline[0].config_recorder_name, null)
}

output "detector_id" {
  value = try(module.guardduty_member_detector[0].detector_id, null)
}

output "access_analyzer_arn" {
  value = try(module.security_baseline[0].access_analyzer_arn, null)
}

output "security_findings_sns_topic_arn" {
  value = try(module.security_baseline[0].security_findings_sns_topic_arn, null)
}

output "ecs_exec_audit_event_rule_name" {
  value = try(module.security_baseline[0].ecs_exec_audit_event_rule_name, null)
}

output "inspector_enabled_resource_types" {
  value = try(module.security_baseline[0].inspector_enabled_resource_types, [])
}

output "backup_vault_name" {
  value = module.backup_baseline.backup_vault_name
}

output "backup_plan_id" {
  value = module.backup_baseline.backup_plan_id
}

output "budget_names" {
  value = try(module.budget_alerts[0].budget_names, {})
}

output "budget_arns" {
  value = try(module.budget_alerts[0].budget_arns, {})
}
