output "frontend_cloudfront_url" {
  value       = module.app.frontend_cloudfront_url
  description = "Frontend CloudFront URL from non-prod app deployment root."
}

output "frontend_cloudfront_distribution_id" {
  value       = module.app.frontend_cloudfront_distribution_id
  description = "Frontend CloudFront distribution ID from non-prod app deployment root."
}

output "frontend_aliases" {
  value       = module.app.frontend_aliases
  description = "Frontend DNS aliases from non-prod app deployment root."
}

output "frontend_cert_arn" {
  value       = module.app.frontend_cert_arn
  description = "Frontend CloudFront ACM certificate ARN from non-prod app deployment root."
}

output "rds_endpoint" {
  value       = module.app.rds_endpoint
  description = "RDS endpoint from non-prod app deployment root."
}

output "rds_instance_id" {
  value       = module.app.rds_instance_id
  description = "RDS instance identifier from non-prod app deployment root."
}

output "rds_instance_arn" {
  value       = module.app.rds_instance_arn
  description = "RDS instance ARN from non-prod app deployment root."
}

output "rds_master_user_secret_arn" {
  value       = module.app.rds_master_user_secret_arn
  description = "Secrets Manager ARN for the non-production RDS master user credentials."
  sensitive   = true
}

output "rds_master_user_secret_rotation_stack_name" {
  value       = module.app.rds_master_user_secret_rotation_stack_name
  description = "CloudFormation stack managing the non-production RDS master-user secret rotation Lambda."
}

output "cost_optimized_dev_tier_enabled" {
  value       = module.app.cost_optimized_dev_tier_enabled
  description = "Whether the cost-optimized dev tier profile is active for this root."
}

output "effective_private_app_nat_mode" {
  value       = module.app.effective_private_app_nat_mode
  description = "Effective private app NAT mode after deployment-contract overrides."
}

output "managed_waf_enabled" {
  value       = module.app.managed_waf_enabled
  description = "Whether managed WAF remains enabled for the non-prod root after deployment-contract overrides."
}

output "aws_backup_enabled" {
  value       = module.app.aws_backup_enabled
  description = "Whether per-root AWS Backup remains enabled for the non-prod root after deployment-contract overrides."
}

output "budget_alerts_enabled" {
  value       = module.app.budget_alerts_enabled
  description = "Whether optional AWS Budgets alerts are enabled for the non-prod root."
}

output "budget_names" {
  value       = module.app.budget_names
  description = "Budget names keyed by logical budget category from the non-prod root."
}

output "operational_alarm_names" {
  value       = module.app.operational_alarm_names
  description = "Workload operational alarm names keyed by alarm purpose from the non-prod root."
}

output "rds_multi_az_enabled" {
  value       = module.app.rds_multi_az_enabled
  description = "Whether the non-production RDS instance is deployed in Multi-AZ mode."
}

output "backend_ecs_cluster_name" {
  value       = module.app.backend_ecs_cluster_name
  description = "ECS cluster name from non-prod app deployment root."
}

output "backend_ecs_service_name" {
  value       = module.app.backend_ecs_service_name
  description = "ECS service name from non-prod app deployment root."
}

output "app_runtime_mode" {
  value       = module.app.app_runtime_mode
  description = "Active runtime mode from non-prod app deployment root."
}

output "public_service_name" {
  value       = module.app.public_service_name
  description = "Public ECS service name when gateway_microservices mode is enabled."
}

output "ecs_service_names" {
  value       = module.app.ecs_service_names
  description = "ECS service names keyed by logical service name in gateway_microservices mode."
}

output "service_discovery_namespace_name" {
  value       = module.app.service_discovery_namespace_name
  description = "Cloud Map namespace used in gateway_microservices mode."
}

output "alb_access_logs_bucket_name" {
  value       = module.app.alb_access_logs_bucket_name
  description = "Primary-region ALB access logs bucket from non-prod app deployment root."
}

output "alb_access_logs_dr_bucket_name" {
  value       = module.app.alb_access_logs_dr_bucket_name
  description = "DR-region ALB access logs bucket from non-prod app deployment root."
}

output "frontend_bucket_name" {
  value       = module.app.frontend_bucket_name
  description = "Primary frontend bucket from the non-prod app deployment root in frontend s3 mode; null in frontend ecs mode."
}

output "backend_alb_arn" {
  value       = module.app.backend_alb_arn
  description = "Internal backend ALB ARN from non-prod app deployment root."
}

output "security_baseline_log_bucket_name" {
  value       = module.app.security_baseline_log_bucket_name
  description = "Primary security baseline log bucket from non-prod app deployment root."
}

output "security_baseline_log_bucket_dr_name" {
  value       = module.app.security_baseline_log_bucket_dr_name
  description = "DR-region security baseline log bucket from non-prod app deployment root."
}

output "security_baseline_cloudtrail_arn" {
  value       = module.app.security_baseline_cloudtrail_arn
  description = "Account-level CloudTrail ARN from non-prod app deployment root."
}

output "security_baseline_ecs_exec_audit_event_rule_name" {
  value       = module.app.security_baseline_ecs_exec_audit_event_rule_name
  description = "EventBridge rule name routing non-production ECS Exec invocations to the security notifications topic when enabled."
}

output "backup_vault_name" {
  value       = module.app.backup_vault_name
  description = "Per-root AWS Backup vault name from non-prod app deployment root."
}

output "backup_plan_id" {
  value       = module.app.backup_plan_id
  description = "Per-root AWS Backup plan ID from non-prod app deployment root."
}

output "route53_zone_id_effective" {
  value       = module.app.route53_zone_id_effective
  description = "Route53 hosted zone ID used by the non-prod app deployment root."
}
