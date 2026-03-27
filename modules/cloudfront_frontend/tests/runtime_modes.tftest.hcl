mock_provider "aws" {}

variables {
  frontend_aliases   = ["app.example.com"]
  frontend_cert_arn  = "arn:aws:acm:us-east-1:111111111111:certificate/example"
  access_logs_bucket = "logs.example.com.s3.amazonaws.com"
}

run "s3_frontend_origin_group" {
  command = plan

  variables {
    frontend_runtime_mode   = "s3"
    frontend_bucket_domain  = "frontend-primary.s3.amazonaws.com"
    secondary_bucket_domain = "frontend-dr.s3.amazonaws.com"
  }

  assert {
    condition     = aws_cloudfront_distribution.frontend.default_cache_behavior[0].target_origin_id == "frontend-origin-group"
    error_message = "S3 frontend mode should target the S3 origin group."
  }
}

run "ecs_frontend_custom_origin" {
  command = plan

  variables {
    frontend_runtime_mode    = "ecs"
    frontend_alb_domain_name = "alb.example.com"
  }

  assert {
    condition     = aws_cloudfront_distribution.frontend.default_cache_behavior[0].target_origin_id == "frontend-alb-origin"
    error_message = "ECS frontend mode should target the ALB origin."
  }
}

run "backend_path_routing_enabled" {
  command = plan

  variables {
    frontend_runtime_mode      = "ecs"
    frontend_alb_domain_name   = "frontend-alb.example.com"
    backend_origin_enabled     = true
    backend_origin_domain_name = "backend-alb.example.com"
    backend_path_patterns      = ["/api/*", "/auth/*"]
  }

  assert {
    condition     = length(aws_cloudfront_distribution.frontend.ordered_cache_behavior) == 2
    error_message = "Backend path routing should add ordered cache behaviors for API paths."
  }
}
