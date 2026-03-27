module "guardduty_member_detector" {
  count  = var.security.account_security_controls_enabled ? 1 : 0
  source = "../../../guardduty_member_detector"
}

#checkov:skip=CKV2_AWS_10: CloudTrail to CloudWatch integration is configured in module.security_baseline but may report false positives in graph checks.
#checkov:skip=CKV2_AWS_45: AWS Config recorder status is enabled in module.security_baseline; this graph check can report false positives with split recorder/status resources.
module "security_baseline" {
  count  = var.security.account_security_controls_enabled ? 1 : 0
  source = "../../../security_baseline"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix                         = var.security.name_prefix
  log_bucket_name                     = var.security.log_bucket_name
  securityhub_standards               = var.security.securityhub_standards
  cloudtrail_retention_days           = var.security.cloudtrail_retention_days
  access_logs_bucket_name             = var.security.access_logs_bucket_name
  access_logs_bucket_name_dr          = var.security.access_logs_bucket_name_dr
  enable_aws_config                   = var.security.enable_aws_config
  security_findings_sns_topic_arn     = var.security.security_findings_sns_topic_arn
  security_findings_sns_subscriptions = var.security.security_findings_sns_subscriptions
  enable_cloudtrail_data_events       = var.security.enable_cloudtrail_data_events
  cloudtrail_data_event_resources     = var.security.cloudtrail_data_event_resources
  enable_inspector                    = var.security.enable_inspector
  enable_ecs_exec_audit_alerts        = var.security.enable_ecs_exec_audit_alerts
  enable_log_bucket_object_lock       = var.security.enable_log_bucket_object_lock
  log_bucket_force_destroy            = var.security.log_bucket_force_destroy
}

module "backup_baseline" {
  source = "../../../backup_baseline"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix                      = var.backup.name_prefix
  enable_aws_backup                = var.backup.enable_aws_backup
  enable_backup_selection          = true
  backup_vault_name                = var.backup.backup_vault_name
  backup_schedule_expression       = var.backup.backup_schedule_expression
  backup_retention_days            = var.backup.backup_retention_days
  backup_start_window_minutes      = var.backup.backup_start_window_minutes
  backup_completion_window_minutes = var.backup.backup_completion_window_minutes
  backup_cross_region_copy_enabled = var.backup.backup_cross_region_copy_enabled
  backup_copy_retention_days       = var.backup.backup_copy_retention_days
  backup_resource_arns = compact([
    var.backup.rds_instance_arn,
    var.backup.frontend_primary_bucket_arn
  ])
}

module "budget_alerts" {
  count  = try(var.budget.enable_budget_alerts, false) ? 1 : 0
  source = "../../../budget_alerts"

  enable_budget_alerts         = var.budget.enable_budget_alerts
  name_prefix                  = var.budget.name_prefix
  notification_email_addresses = var.budget.notification_email_addresses
  notification_topic_arns      = var.budget.notification_topic_arns
  alert_threshold_percentages  = var.budget.alert_threshold_percentages
  total_monthly_limit          = var.budget.total_monthly_limit
  cloudfront_monthly_limit     = var.budget.cloudfront_monthly_limit
  vpc_monthly_limit            = var.budget.vpc_monthly_limit
  rds_monthly_limit            = var.budget.rds_monthly_limit
}
