output "vpc_id" {
  value = module.edge_contract.selected_vpc_id
}

output "cost_optimized_dev_tier_enabled" {
  value       = module.deployment_contract.cost_optimized_dev_tier_enabled
  description = "Whether the cost-optimized dev tier profile is active."
}

output "effective_private_app_nat_mode" {
  value       = module.deployment_contract.effective_private_app_nat_mode
  description = "Effective private app subnet NAT mode after deployment-contract overrides."
}

output "managed_waf_enabled" {
  value       = module.deployment_contract.effective_enable_managed_waf
  description = "Whether managed WAF remains enabled after deployment-contract overrides."
}

output "aws_backup_enabled" {
  value       = module.deployment_contract.effective_enable_aws_backup
  description = "Whether per-root AWS Backup remains enabled after deployment-contract overrides."
}

output "public_app_subnet_ids" {
  value       = module.edge_contract.selected_public_edge_subnet_ids
  description = "Public edge subnet IDs used by NAT/egress routing."
}

output "private_app_subnet_ids" {
  value       = module.edge_contract.selected_private_app_subnet_ids
  description = "Private app subnet IDs used by backend ECS service"
}

output "db_subnet_ids" {
  value = module.edge_contract.selected_db_subnet_ids
}

output "frontend_cloudfront_url" {
  value = module.frontend_edge.frontend_url
}

output "frontend_cloudfront_distribution_id" {
  value       = module.frontend_edge.frontend_distribution_id
  description = "Frontend CloudFront distribution ID."
}

output "representative_resource_tags" {
  value = {
    vpc = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = module.deployment_contract.environment_name
        Name        = var.vpc_name
      },
      var.resource_contract_tags
    )
    rds = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = module.deployment_contract.environment_name
        Name        = module.app_data.instance_identifier
      },
      var.resource_contract_tags
    )
    frontend_distribution = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = module.deployment_contract.environment_name
        Name        = module.deployment_contract.enable_environment_suffix ? "cloudfront-frontend-${module.deployment_contract.environment_name}" : "cloudfront-frontend"
      },
      var.resource_contract_tags
    )
  }
  description = "Representative effective tag contracts for the VPC, RDS instance, and frontend CloudFront distribution."
}

output "frontend_aliases" {
  value       = module.edge_contract.frontend_aliases
  description = "Frontend DNS aliases managed by the deployment."
}

output "frontend_cert_arn" {
  value       = var.acm_cert_frontend
  description = "ACM certificate ARN used by the frontend CloudFront distribution."
}

output "rds_endpoint" {
  value = module.app_data.endpoint
}

output "rds_instance_id" {
  value       = module.app_data.instance_identifier
  description = "RDS instance identifier."
}

output "rds_instance_arn" {
  value       = module.app_data.instance_arn
  description = "RDS instance ARN."
}

output "rds_multi_az_enabled" {
  value       = module.deployment_contract.effective_rds_multi_az
  description = "Whether the workload RDS instance is deployed in Multi-AZ mode."
}

output "backend_effective_desired_count" {
  value       = module.deployment_contract.effective_backend_desired_count
  description = "Effective desired count for the single-backend ECS service after deployment-contract overrides."
}

output "backend_effective_min_count" {
  value       = module.deployment_contract.effective_backend_min_count
  description = "Effective minimum count for the single-backend ECS service after deployment-contract overrides."
}

output "backend_effective_max_count" {
  value       = module.deployment_contract.effective_backend_max_count
  description = "Effective maximum count for the single-backend ECS service after deployment-contract overrides."
}

output "backend_alb_dns_name" {
  value       = module.backend_edge.alb_dns_name
  description = "Backend ALB DNS name used as CloudFront origin."
}

output "backend_alb_arn" {
  value       = module.backend_edge.alb_arn
  description = "Internal backend ALB ARN."
}

output "backend_alb_target_group_arn" {
  value       = module.backend_edge.target_group_arn
  description = "Backend ALB target group ARN attached to the ECS service."
}

output "backend_service_security_group_id" {
  value = module.networking.backend_service_security_group_id
}

output "backend_alb_security_group_id" {
  value = module.networking.backend_alb_security_group_id
}

output "rds_security_group_id" {
  value = module.networking.rds_security_group_id
}

output "backend_ecs_cluster_name" {
  value       = module.app_runtime.backend_ecs_cluster_name
  description = "Backend ECS cluster name."
}

output "backend_ecs_service_name" {
  value       = module.app_runtime.backend_ecs_service_name
  description = "Backend ECS service name."
}

output "backend_ecs_task_definition_arn" {
  value       = module.app_runtime.backend_ecs_task_definition_arn
  description = "Backend ECS task definition ARN."
}

output "app_runtime_mode" {
  value       = var.app_runtime_mode
  description = "Active application runtime mode."
}

output "service_discovery_namespace_name" {
  value       = module.app_runtime.service_discovery_namespace_name
  description = "Cloud Map private DNS namespace used in gateway_microservices mode."
}

output "ecs_service_names" {
  value       = module.app_runtime.ecs_service_names
  description = "ECS service names keyed by logical service name in gateway_microservices mode."
}

output "public_service_name" {
  value       = module.app_runtime.public_service_name
  description = "Public ECS service name attached to the backend ALB in gateway_microservices mode."
}

output "rds_master_user_secret_arn" {
  value       = module.app_data.master_user_secret_arn
  description = "Secrets Manager ARN for the RDS-managed master user credentials."
  sensitive   = true
}

output "rds_master_user_secret_rotation_stack_name" {
  value       = module.app_data.master_user_secret_rotation_stack_name
  description = "CloudFormation stack name managing the hosted Secrets Manager rotation Lambda for the RDS master user secret."
}

output "cloudfront_logs_bucket_name" {
  value       = module.access_log_storage.cloudfront_logs_bucket_id
  description = "CloudFront access logs bucket."
}

output "frontend_bucket_name" {
  value       = module.edge_contract.frontend_primary_bucket_name
  description = "Primary frontend content bucket in frontend s3 mode; null in frontend ecs mode."
}

output "s3_access_logs_bucket_name" {
  value       = module.access_log_storage.s3_access_logs_bucket_id
  description = "Centralized S3 server access logs bucket."
}

output "alb_access_logs_bucket_name" {
  value       = module.access_log_storage.alb_access_logs_bucket_id
  description = "Primary-region ALB access logs bucket."
}

output "alb_access_logs_dr_bucket_name" {
  value       = module.access_log_storage.alb_access_logs_dr_bucket_id
  description = "DR-region ALB access logs bucket."
}

output "frontend_dr_bucket_name" {
  value       = module.edge_contract.frontend_dr_bucket_name
  description = "DR replica bucket for frontend content in frontend s3 mode; null in frontend ecs mode."
}

output "cloudfront_logs_dr_bucket_name" {
  value       = module.access_log_storage.cloudfront_logs_dr_bucket_id
  description = "DR replica bucket for CloudFront logs."
}

output "vpc_flow_logs_log_group_name" {
  value       = module.networking.vpc_flow_logs_log_group_name
  description = "VPC Flow Logs log group name."
}

output "security_baseline_cloudtrail_arn" {
  value       = module.platform_governance.cloudtrail_arn
  description = "CloudTrail ARN from the security baseline module."
}

output "security_baseline_log_bucket_name" {
  value       = module.platform_governance.log_bucket_name
  description = "Security baseline S3 log bucket name."
}

output "security_baseline_log_bucket_dr_name" {
  value       = module.platform_governance.log_bucket_dr_name
  description = "Security baseline DR S3 log bucket name."
}

output "security_baseline_config_recorder_name" {
  value       = module.platform_governance.config_recorder_name
  description = "AWS Config recorder name from the security baseline module."
}

output "security_baseline_guardduty_detector_id" {
  value       = module.platform_governance.detector_id
  description = "Account-local GuardDuty detector ID for the deployment."
}

output "security_baseline_access_analyzer_arn" {
  value       = module.platform_governance.access_analyzer_arn
  description = "IAM Access Analyzer ARN from the security baseline module."
}

output "security_baseline_findings_sns_topic_arn" {
  value       = module.platform_governance.security_findings_sns_topic_arn
  description = "SNS topic ARN receiving GuardDuty/Security Hub high-severity findings."
}

output "security_baseline_ecs_exec_audit_event_rule_name" {
  value       = module.platform_governance.ecs_exec_audit_event_rule_name
  description = "EventBridge rule name forwarding ECS Exec invocations to the security notifications topic."
}

output "security_baseline_backup_vault_name" {
  value       = module.platform_governance.backup_vault_name
  description = "Compatibility alias for the per-root AWS Backup vault name."
}

output "security_baseline_backup_plan_id" {
  value       = module.platform_governance.backup_plan_id
  description = "Compatibility alias for the per-root AWS Backup plan ID."
}

output "security_baseline_inspector_resource_types" {
  value       = module.platform_governance.inspector_enabled_resource_types
  description = "Amazon Inspector enabled resource types from the security baseline module."
}

output "backup_vault_name" {
  value       = module.platform_governance.backup_vault_name
  description = "Per-root AWS Backup vault name."
}

output "backup_plan_id" {
  value       = module.platform_governance.backup_plan_id
  description = "Per-root AWS Backup plan ID."
}

output "budget_alerts_enabled" {
  value       = var.enable_budget_alerts
  description = "Whether optional AWS Budgets alerts are enabled for this deployment."
}

output "budget_names" {
  value       = module.platform_governance.budget_names
  description = "Budget names keyed by logical budget category."
}

output "budget_arns" {
  value       = module.platform_governance.budget_arns
  description = "Budget ARNs keyed by logical budget category."
}

output "operational_alarm_names" {
  value       = module.operational_observability.alarm_names
  description = "Workload operational alarm names keyed by alarm purpose."
}

output "backend_ecr_repository_name" {
  value       = module.app_runtime.backend_ecr_repository_name
  description = "Managed backend ECR repository name when create_backend_ecr_repository=true."
}

output "backend_ecr_repository_url" {
  value       = module.app_runtime.backend_ecr_repository_url
  description = "Managed backend ECR repository URL when create_backend_ecr_repository=true."
}

output "route53_zone_id_effective" {
  value       = module.edge_contract.route53_zone_id_effective
  description = "Route53 hosted zone ID used for public DNS records."
}

output "route53_zone_name_effective" {
  value       = module.edge_contract.route53_zone_name_effective
  description = "Route53 hosted zone name discovered or managed for public DNS records."
}

output "route53_zone_managed" {
  value       = module.edge_contract.route53_zone_managed
  description = "Whether Terraform created and therefore manages the public hosted zone."
}
