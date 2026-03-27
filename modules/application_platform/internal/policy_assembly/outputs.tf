output "backend_env_final" {
  value = local.backend_env_final
}

output "backend_secret_arns_final" {
  value = local.backend_secret_arns_final
}

output "ecs_services_final" {
  value = local.ecs_services_final
}

output "public_service_keys" {
  value = local.public_service_keys
}

output "public_service_key" {
  value = local.public_service_key
}

output "public_service_port" {
  value = local.public_service_input != null ? local.public_service_input.container_port : null
}

output "public_service_health_check_path" {
  value = local.public_service_input != null ? coalesce(try(local.public_service_input.health_check_path, null), "/health") : null
}

output "microservice_image_repositories" {
  value = local.microservice_image_repositories
}
