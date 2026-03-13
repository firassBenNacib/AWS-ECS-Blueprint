output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_edge_subnet_ids" {
  description = "Public subnet IDs used by ALB and NAT gateways"
  value       = aws_subnet.public_edge[*].id
}

output "public_app_subnet_ids" {
  description = "Legacy alias of public_edge_subnet_ids"
  value       = aws_subnet.public_edge[*].id
}

output "private_app_subnet_ids" {
  description = "Private subnet IDs used by backend service tasks"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "Private subnet IDs used by RDS"
  value       = aws_subnet.private_db[*].id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs used for private app egress"
  value       = aws_nat_gateway.this[*].id
}

output "vpc_flow_logs_log_group_name" {
  description = "VPC Flow Logs CloudWatch log group name"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "interface_endpoints_sg_id" {
  description = "Security group ID attached to Interface VPC Endpoints"
  value       = aws_security_group.interface_endpoints.id
}

output "s3_gateway_endpoint_id" {
  description = "Gateway VPC Endpoint ID for Amazon S3"
  value       = aws_vpc_endpoint.s3_gateway.id
}

output "s3_gateway_prefix_list_id" {
  description = "Managed prefix list ID for Amazon S3 in the current region"
  value       = data.aws_prefix_list.s3.id
}
