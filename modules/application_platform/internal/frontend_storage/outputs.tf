output "frontend_primary_bucket_name" {
  value = var.frontend.runtime_is_s3 ? module.s3[0].bucket_name : null
}

output "frontend_primary_bucket_domain" {
  value = var.frontend.runtime_is_s3 ? module.s3[0].bucket_domain_name : ""
}

output "frontend_primary_bucket_arn" {
  value = var.frontend.runtime_is_s3 ? module.s3[0].bucket_arn : null
}

output "frontend_dr_bucket_name" {
  value = var.frontend.runtime_is_s3 ? aws_s3_bucket.frontend_dr[0].id : null
}

output "frontend_dr_bucket_domain" {
  value = var.frontend.runtime_is_s3 ? aws_s3_bucket.frontend_dr[0].bucket_regional_domain_name : ""
}

output "frontend_dr_bucket_arn" {
  value = var.frontend.runtime_is_s3 ? aws_s3_bucket.frontend_dr[0].arn : null
}
