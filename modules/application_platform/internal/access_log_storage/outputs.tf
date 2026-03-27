output "s3_access_logs_bucket_id" {
  value = aws_s3_bucket.s3_access_logs.id
}

output "s3_access_logs_bucket_policy_id" {
  value = aws_s3_bucket_policy.s3_access_logs_bucket.id
}

output "s3_access_logs_dr_bucket_id" {
  value = aws_s3_bucket.s3_access_logs_dr.id
}

output "s3_access_logs_dr_bucket_policy_id" {
  value = aws_s3_bucket_policy.s3_access_logs_dr_bucket.id
}

output "alb_access_logs_bucket_id" {
  value = aws_s3_bucket.alb_access_logs.id
}

output "alb_access_logs_dr_bucket_id" {
  value = aws_s3_bucket.alb_access_logs_dr.id
}

output "cloudfront_logs_bucket_id" {
  value = aws_s3_bucket.cloudfront_logs.id
}

output "cloudfront_logs_bucket_domain" {
  value = aws_s3_bucket.cloudfront_logs.bucket_domain_name
}

output "cloudfront_logs_dr_bucket_id" {
  value = aws_s3_bucket.cloudfront_logs_dr.id
}
