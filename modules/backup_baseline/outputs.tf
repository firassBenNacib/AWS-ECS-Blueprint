output "backup_vault_name" {
  description = "Primary AWS Backup vault name."
  value       = try(aws_backup_vault.primary[0].name, null)
}

output "backup_plan_id" {
  description = "AWS Backup plan ID."
  value       = try(aws_backup_plan.this[0].id, null)
}

output "backup_role_arn" {
  description = "AWS Backup service role ARN."
  value       = try(aws_iam_role.backup[0].arn, null)
}
