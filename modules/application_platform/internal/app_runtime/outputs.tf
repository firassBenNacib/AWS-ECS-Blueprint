output "backend_ecr_repository_name" {
  value = try(module.ecr_backend[0].repository_name, null)
}

output "backend_ecr_repository_url" {
  value = try(module.ecr_backend[0].repository_url, null)
}

output "backend_ecs_cluster_name" {
  value = var.runtime.runtime_mode_is_single ? module.ecs_backend[0].cluster_name : aws_ecs_cluster.microservices[0].name
}

output "backend_ecs_service_name" {
  value = var.runtime.runtime_mode_is_single ? module.ecs_backend[0].service_name : module.ecs_service[var.runtime.public_service_key].service_name
}

output "backend_ecs_task_definition_arn" {
  value = var.runtime.runtime_mode_is_single ? module.ecs_backend[0].task_definition_arn : module.ecs_service[var.runtime.public_service_key].task_definition_arn
}

output "service_discovery_namespace_name" {
  value = var.runtime.runtime_mode_is_micro ? aws_service_discovery_private_dns_namespace.microservices[0].name : null
}

output "ecs_service_names" {
  value = var.runtime.runtime_mode_is_micro ? { for service_name, service in module.ecs_service : service_name => service.service_name } : {}
}

output "public_service_name" {
  value = var.runtime.runtime_mode_is_micro ? module.ecs_service[var.runtime.public_service_key].service_name : null
}
