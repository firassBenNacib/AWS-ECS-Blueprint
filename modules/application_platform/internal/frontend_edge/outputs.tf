output "frontend_url" {
  value = module.cloudfront_frontend.frontend_url
}

output "frontend_distribution_id" {
  value = module.cloudfront_frontend.frontend_distribution_id
}

output "frontend_distribution_arn" {
  value = module.cloudfront_frontend.frontend_distribution_arn
}

output "frontend_hosted_zone_id" {
  value = module.cloudfront_frontend.frontend_hosted_zone_id
}
