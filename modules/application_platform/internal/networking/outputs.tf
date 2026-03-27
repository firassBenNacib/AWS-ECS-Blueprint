output "vpc_id" {
  value = module.network.vpc_id
}

output "interface_endpoints_sg_id" {
  value = module.network.interface_endpoints_sg_id
}

output "s3_gateway_prefix_list_id" {
  value = module.network.s3_gateway_prefix_list_id
}

output "public_edge_subnet_ids" {
  value = module.network.public_edge_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.network.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.network.private_db_subnet_ids
}

output "vpc_flow_logs_log_group_name" {
  value = module.network.vpc_flow_logs_log_group_name
}

output "backend_service_security_group_id" {
  value = var.security.runtime_mode_is_single ? module.security_groups[0].backend_service_sg_id : aws_security_group.microservices_gateway[0].id
}

output "backend_alb_security_group_id" {
  value = var.security.runtime_mode_is_single ? module.security_groups[0].backend_alb_sg_id : aws_security_group.microservices_alb[0].id
}

output "rds_security_group_id" {
  value = var.security.runtime_mode_is_single ? module.security_groups[0].rds_sg_id : aws_security_group.microservices_rds[0].id
}

output "microservices_alb_security_group_id" {
  value = var.security.runtime_mode_is_micro ? aws_security_group.microservices_alb[0].id : null
}

output "microservices_gateway_security_group_id" {
  value = var.security.runtime_mode_is_micro ? aws_security_group.microservices_gateway[0].id : null
}

output "microservices_internal_security_group_id" {
  value = var.security.runtime_mode_is_micro ? aws_security_group.microservices_internal[0].id : null
}

output "microservices_extra_egress_security_group_ids" {
  value = { for service_name, sg in aws_security_group.microservices_extra_egress : service_name => sg.id }
}
