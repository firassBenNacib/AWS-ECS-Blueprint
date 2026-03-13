output "alb_arn" {
  description = "Backend ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Backend ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Backend ALB hosted zone ID"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "Backend ALB target group ARN"
  value       = aws_lb_target_group.backend.arn
}

output "alb_arn_suffix" {
  description = "Backend ALB ARN suffix used for CloudWatch metrics dimensions."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Backend target group ARN suffix used for CloudWatch metrics dimensions."
  value       = aws_lb_target_group.backend.arn_suffix
}
