output "vpc_id" {
  value = local.selected_vpc_id
}

output "public_app_subnet_ids" {
  value       = local.selected_public_edge_subnet_ids
  description = "Public edge subnet IDs used by NAT/egress routing."
}

output "private_app_subnet_ids" {
  value       = local.selected_private_app_subnet_ids
  description = "Private app subnet IDs used by backend ECS service"
}

output "db_subnet_ids" {
  value = local.selected_db_subnet_ids
}

output "frontend_cloudfront_url" {
  value = module.cloudfront_frontend.frontend_url
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_instance_id" {
  value       = module.rds.instance_identifier
  description = "RDS instance identifier."
}

output "rds_instance_arn" {
  value       = module.rds.instance_arn
  description = "RDS instance ARN."
}

output "backend_alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Backend ALB DNS name used as CloudFront origin."
}

output "backend_alb_arn" {
  value       = module.alb.alb_arn
  description = "Internal backend ALB ARN."
}

output "backend_alb_target_group_arn" {
  value       = module.alb.target_group_arn
  description = "Backend ALB target group ARN attached to the ECS service."
}

output "backend_service_security_group_id" {
  value = local.runtime_mode_is_single ? module.security_groups[0].backend_service_sg_id : aws_security_group.microservices_gateway[0].id
}

output "backend_alb_security_group_id" {
  value = local.runtime_mode_is_single ? module.security_groups[0].backend_alb_sg_id : aws_security_group.microservices_alb[0].id
}

output "rds_security_group_id" {
  value = local.runtime_mode_is_single ? module.security_groups[0].rds_sg_id : aws_security_group.microservices_rds[0].id
}

output "backend_ecs_cluster_name" {
  value       = local.runtime_mode_is_single ? module.ecs_backend[0].cluster_name : aws_ecs_cluster.microservices[0].name
  description = "Backend ECS cluster name."
}

output "backend_ecs_service_name" {
  value       = local.runtime_mode_is_single ? module.ecs_backend[0].service_name : module.ecs_service[local.public_service_key].service_name
  description = "Backend ECS service name."
}

output "backend_ecs_task_definition_arn" {
  value       = local.runtime_mode_is_single ? module.ecs_backend[0].task_definition_arn : module.ecs_service[local.public_service_key].task_definition_arn
  description = "Backend ECS task definition ARN."
}

output "app_runtime_mode" {
  value       = var.app_runtime_mode
  description = "Active application runtime mode."
}

output "service_discovery_namespace_name" {
  value       = local.runtime_mode_is_micro ? aws_service_discovery_private_dns_namespace.microservices[0].name : null
  description = "Cloud Map private DNS namespace used in gateway_microservices mode."
}

output "ecs_service_names" {
  value       = local.runtime_mode_is_micro ? { for service_name, service in module.ecs_service : service_name => service.service_name } : {}
  description = "ECS service names keyed by logical service name in gateway_microservices mode."
}

output "public_service_name" {
  value       = local.runtime_mode_is_micro ? module.ecs_service[local.public_service_key].service_name : null
  description = "Public ECS service name attached to the backend ALB in gateway_microservices mode."
}

output "rds_master_user_secret_arn" {
  value       = module.rds.master_user_secret_arn
  description = "Secrets Manager ARN for the RDS-managed master user credentials."
}

output "cloudfront_logs_bucket_name" {
  value       = aws_s3_bucket.cloudfront_logs.id
  description = "CloudFront access logs bucket."
}

output "frontend_bucket_name" {
  value       = module.s3.bucket_name
  description = "Primary frontend content bucket."
}

output "s3_access_logs_bucket_name" {
  value       = aws_s3_bucket.s3_access_logs.id
  description = "Centralized S3 server access logs bucket."
}

output "alb_access_logs_bucket_name" {
  value       = aws_s3_bucket.alb_access_logs.id
  description = "Primary-region ALB access logs bucket."
}

output "alb_access_logs_dr_bucket_name" {
  value       = aws_s3_bucket.alb_access_logs_dr.id
  description = "DR-region ALB access logs bucket."
}

output "frontend_dr_bucket_name" {
  value       = aws_s3_bucket.frontend_dr.id
  description = "DR replica bucket for frontend content."
}

output "cloudfront_logs_dr_bucket_name" {
  value       = aws_s3_bucket.cloudfront_logs_dr.id
  description = "DR replica bucket for CloudFront logs."
}

output "vpc_flow_logs_log_group_name" {
  value       = module.network.vpc_flow_logs_log_group_name
  description = "VPC Flow Logs log group name."
}

output "security_baseline_cloudtrail_arn" {
  value       = try(module.security_baseline[0].cloudtrail_arn, null)
  description = "CloudTrail ARN from the security baseline module."
}

output "security_baseline_log_bucket_name" {
  value       = try(module.security_baseline[0].log_bucket_name, null)
  description = "Security baseline S3 log bucket name."
}

output "security_baseline_log_bucket_dr_name" {
  value       = try(module.security_baseline[0].log_bucket_dr_name, null)
  description = "Security baseline DR S3 log bucket name."
}

output "security_baseline_config_recorder_name" {
  value       = try(module.security_baseline[0].config_recorder_name, null)
  description = "AWS Config recorder name from the security baseline module."
}

output "security_baseline_guardduty_detector_id" {
  value       = try(module.guardduty_member_detector[0].detector_id, null)
  description = "Account-local GuardDuty detector ID for the deployment."
}

output "security_baseline_access_analyzer_arn" {
  value       = try(module.security_baseline[0].access_analyzer_arn, null)
  description = "IAM Access Analyzer ARN from the security baseline module."
}

output "security_baseline_findings_sns_topic_arn" {
  value       = try(module.security_baseline[0].security_findings_sns_topic_arn, null)
  description = "SNS topic ARN receiving GuardDuty/Security Hub high-severity findings."
}

output "security_baseline_backup_vault_name" {
  value       = module.backup_baseline.backup_vault_name
  description = "Compatibility alias for the per-root AWS Backup vault name."
}

output "security_baseline_backup_plan_id" {
  value       = module.backup_baseline.backup_plan_id
  description = "Compatibility alias for the per-root AWS Backup plan ID."
}

output "security_baseline_inspector_resource_types" {
  value       = try(module.security_baseline[0].inspector_enabled_resource_types, [])
  description = "Amazon Inspector enabled resource types from the security baseline module."
}

output "backup_vault_name" {
  value       = module.backup_baseline.backup_vault_name
  description = "Per-root AWS Backup vault name."
}

output "backup_plan_id" {
  value       = module.backup_baseline.backup_plan_id
  description = "Per-root AWS Backup plan ID."
}

output "backend_ecr_repository_name" {
  value       = try(module.ecr_backend[0].repository_name, null)
  description = "Managed backend ECR repository name when create_backend_ecr_repository=true."
}

output "backend_ecr_repository_url" {
  value       = try(module.ecr_backend[0].repository_url, null)
  description = "Managed backend ECR repository URL when create_backend_ecr_repository=true."
}

output "route53_zone_id_effective" {
  value       = local.route53_zone_id_effective
  description = "Route53 hosted zone ID used for public DNS records."
}

output "route53_zone_name_effective" {
  value       = local.route53_zone_name_effective
  description = "Route53 hosted zone name discovered or managed for public DNS records."
}

output "route53_zone_managed" {
  value       = local.route53_zone_managed
  description = "Whether Terraform created and therefore manages the public hosted zone."
}
