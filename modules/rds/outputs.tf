output "endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS hostname without port"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS listener port"
  value       = aws_db_instance.this.port
}

output "instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.this.id
}

output "instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "db_subnet_group_name" {
  description = "RDS DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for RDS-managed master user credentials"
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}
