output "alb_arn" {
  value = module.alb.alb_arn
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_zone_id" {
  value = module.alb.alb_zone_id
}

output "target_group_arn" {
  value = module.alb.target_group_arn
}

output "alb_arn_suffix" {
  value = module.alb.alb_arn_suffix
}

output "target_group_arn_suffix" {
  value = module.alb.target_group_arn_suffix
}

output "backend_vpc_origin_id_final" {
  value = var.ingress.backend_ingress_is_vpc_origin ? aws_cloudfront_vpc_origin.backend_primary[0].id : null
}

output "cloudfront_web_acl_arn" {
  value = try(aws_wafv2_web_acl.cloudfront[0].arn, null)
}
