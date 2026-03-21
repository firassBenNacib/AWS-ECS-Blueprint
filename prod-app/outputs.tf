output "frontend_cloudfront_url" {
  value       = module.app.frontend_cloudfront_url
  description = "Frontend CloudFront URL from prod app deployment root."
}

output "frontend_cloudfront_distribution_id" {
  value       = module.app.frontend_cloudfront_distribution_id
  description = "Frontend CloudFront distribution ID from prod app deployment root."
}

output "rds_endpoint" {
  value       = module.app.rds_endpoint
  description = "RDS endpoint from prod app deployment root."
}

output "rds_instance_id" {
  value       = module.app.rds_instance_id
  description = "RDS instance identifier from prod app deployment root."
}

output "rds_instance_arn" {
  value       = module.app.rds_instance_arn
  description = "RDS instance ARN from prod app deployment root."
}

output "backend_ecs_cluster_name" {
  value       = module.app.backend_ecs_cluster_name
  description = "ECS cluster name from prod app deployment root."
}

output "backend_ecs_service_name" {
  value       = module.app.backend_ecs_service_name
  description = "ECS service name from prod app deployment root."
}

output "app_runtime_mode" {
  value       = module.app.app_runtime_mode
  description = "Active runtime mode from prod app deployment root."
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
  description = "Primary-region ALB access logs bucket from prod app deployment root."
}

output "alb_access_logs_dr_bucket_name" {
  value       = module.app.alb_access_logs_dr_bucket_name
  description = "DR-region ALB access logs bucket from prod app deployment root."
}

output "frontend_bucket_name" {
  value       = module.app.frontend_bucket_name
  description = "Primary frontend bucket from prod app deployment root."
}

output "backend_alb_arn" {
  value       = module.app.backend_alb_arn
  description = "Internal backend ALB ARN from prod app deployment root."
}

output "security_baseline_log_bucket_name" {
  value       = module.app.security_baseline_log_bucket_name
  description = "Primary security baseline log bucket from prod app deployment root."
}

output "security_baseline_log_bucket_dr_name" {
  value       = module.app.security_baseline_log_bucket_dr_name
  description = "DR-region security baseline log bucket from prod app deployment root."
}

output "security_baseline_cloudtrail_arn" {
  value       = module.app.security_baseline_cloudtrail_arn
  description = "Account-level CloudTrail ARN from prod app deployment root."
}

output "backup_vault_name" {
  value       = module.app.backup_vault_name
  description = "Per-root AWS Backup vault name from prod app deployment root."
}

output "backup_plan_id" {
  value       = module.app.backup_plan_id
  description = "Per-root AWS Backup plan ID from prod app deployment root."
}
