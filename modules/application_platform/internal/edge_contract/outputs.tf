output "selected_vpc_id" {
  value = var.networking.vpc_id
}

output "selected_interface_endpoints_sg_id" {
  value = var.networking.interface_endpoints_sg_id
}

output "selected_s3_gateway_prefix_list_id" {
  value = var.networking.s3_gateway_prefix_list_id
}

output "selected_public_edge_subnet_ids" {
  value = local.selected_public_edge_subnet_ids
}

output "selected_private_app_subnet_ids" {
  value = local.selected_private_app_subnet_ids
}

output "selected_db_subnet_ids" {
  value = local.selected_db_subnet_ids
}

output "selected_alb_subnet_ids" {
  value = local.selected_alb_subnet_ids
}

output "frontend_aliases" {
  value = var.routing.frontend_aliases
}

output "backend_path_patterns" {
  value = var.routing.backend_path_patterns
}

output "route53_zone_id_effective" {
  value = var.routing.route53_zone_id_effective
}

output "route53_zone_name_effective" {
  value = var.routing.route53_zone_name_effective
}

output "route53_zone_managed" {
  value = var.routing.route53_zone_managed
}

output "frontend_primary_bucket_name" {
  value = var.frontend.primary_bucket_name
}

output "frontend_primary_bucket_domain" {
  value = var.frontend.primary_bucket_domain
}

output "frontend_primary_bucket_arn" {
  value = var.frontend.primary_bucket_arn
}

output "frontend_dr_bucket_name" {
  value = var.frontend.dr_bucket_name
}

output "dr_frontend_bucket_domain" {
  value = var.frontend.dr_bucket_domain
}

output "frontend_dr_bucket_arn" {
  value = var.frontend.dr_bucket_arn
}

output "frontend_primary_bucket_arn_expected" {
  value = local.frontend_primary_bucket_arn_expected
}

output "frontend_dr_bucket_arn_expected" {
  value = local.frontend_dr_bucket_arn_expected
}

output "cloudfront_logs_bucket_domain" {
  value = var.frontend.cloudfront_logs_domain
}

output "create_managed_waf_alb" {
  value = var.routing.create_managed_waf_alb
}

output "create_managed_waf_cloudfront" {
  value = var.routing.create_managed_waf_cloudfront
}
