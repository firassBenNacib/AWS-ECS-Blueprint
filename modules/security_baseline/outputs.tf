output "cloudtrail_arn" {
  description = "ARN of the multi-region CloudTrail"
  value       = aws_cloudtrail.this.arn
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.this.name
}

output "log_bucket_name" {
  description = "S3 bucket used for security baseline logs"
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_dr_name" {
  description = "DR-region replica bucket used for security baseline logs."
  value       = aws_s3_bucket.logs_dr.id
}

output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = try(aws_config_configuration_recorder.this[0].name, null)
}

output "securityhub_account_id" {
  description = "Security Hub account ID"
  value       = try(aws_securityhub_account.this[0].id, null)
}

output "securityhub_standards_subscription_arns" {
  description = "Security Hub standards subscription ARNs"
  value       = [for sub in aws_securityhub_standards_subscription.this : sub.id]
}

output "access_analyzer_arn" {
  description = "IAM Access Analyzer ARN"
  value       = try(aws_accessanalyzer_analyzer.this[0].arn, null)
}

output "security_findings_sns_topic_arn" {
  description = "SNS topic ARN receiving GuardDuty/Security Hub high-severity findings."
  value       = local.security_findings_topic_arn
}

output "security_findings_event_rule_names" {
  description = "EventBridge rule names forwarding high-severity security findings."
  value = compact([
    aws_cloudwatch_event_rule.guardduty_high_critical.name,
    try(aws_cloudwatch_event_rule.securityhub_high_critical[0].name, null),
    try(aws_cloudwatch_event_rule.ecs_exec_invocations[0].name, null)
  ])
}

output "ecs_exec_audit_event_rule_name" {
  description = "EventBridge rule name forwarding ECS Exec invocations to security notifications."
  value       = try(aws_cloudwatch_event_rule.ecs_exec_invocations[0].name, null)
}

output "inspector_enabled_resource_types" {
  description = "Amazon Inspector enabled resource types."
  value       = try(aws_inspector2_enabler.this[0].resource_types, [])
}
