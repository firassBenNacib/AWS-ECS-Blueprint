output "endpoint" {
  value = module.rds.endpoint
}

output "address" {
  value = module.rds.address
}

output "instance_identifier" {
  value = module.rds.instance_identifier
}

output "instance_arn" {
  value = module.rds.instance_arn
}

output "master_user_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "master_user_secret_rotation_stack_name" {
  value = try(aws_cloudformation_stack.master_user_secret_rotation[0].name, null)
}
