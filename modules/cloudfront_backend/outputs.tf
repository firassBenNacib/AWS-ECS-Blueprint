output "backend_url" {
  value = aws_cloudfront_distribution.backend.domain_name
}

output "backend_distribution_id" {
  value = aws_cloudfront_distribution.backend.id
}

output "backend_distribution_arn" {
  value = aws_cloudfront_distribution.backend.arn
}

output "backend_hosted_zone_id" {
  value = aws_cloudfront_distribution.backend.hosted_zone_id
}
