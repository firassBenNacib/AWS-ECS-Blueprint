output "backend_service_sg_id" {
  description = "Security group ID for backend ECS service tasks"
  value       = aws_security_group.backend_service.id
}

output "backend_alb_sg_id" {
  description = "Security group ID for backend ALB"
  value       = aws_security_group.backend_alb.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}
