output "bucket_name" {
  description = "Frontend S3 bucket name."
  value       = aws_s3_bucket.frontend.id
}

output "bucket_domain_name" {
  description = "Frontend S3 bucket regional domain name used for CloudFront origin."
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "bucket_arn" {
  description = "Frontend S3 bucket ARN."
  value       = aws_s3_bucket.frontend.arn
}
