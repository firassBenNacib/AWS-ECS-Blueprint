output "backend_url" {
  description = "Backend CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.backend.domain_name
}

output "backend_distribution_id" {
  description = "Backend CloudFront distribution ID."
  value       = aws_cloudfront_distribution.backend.id
}

output "backend_distribution_arn" {
  description = "Backend CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.backend.arn
}

output "backend_hosted_zone_id" {
  description = "Backend CloudFront distribution Route53 hosted zone ID."
  value       = aws_cloudfront_distribution.backend.hosted_zone_id
}
