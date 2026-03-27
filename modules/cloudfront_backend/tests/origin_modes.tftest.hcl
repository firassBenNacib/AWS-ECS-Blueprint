mock_provider "aws" {}

variables {
  backend_domain_name          = "backend-alb.example.com"
  backend_failover_domain_name = "backend-failover.example.com"
  backend_alias                = "api.example.com"
  backend_cert_arn             = "arn:aws:acm:us-east-1:111111111111:certificate/example"
  cache_policy_id              = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  origin_request_policy_id     = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  access_logs_bucket           = "logs.example.com.s3.amazonaws.com"
}

run "vpc_origin_mode" {
  command = plan

  variables {
    backend_vpc_origin_id = "vpc-origin-123456"
  }

  assert {
    condition     = aws_cloudfront_distribution.backend.default_cache_behavior[0].target_origin_id == "backend-alb-origin"
    error_message = "Backend distribution should use the primary ALB origin by default."
  }
}

run "custom_origin_mode" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.backend.default_cache_behavior[0].target_origin_id == "backend-alb-origin"
    error_message = "Custom-origin mode should still target the primary ALB origin."
  }
}

run "waf_arn_pass_through" {
  command = plan

  variables {
    web_acl_id = "arn:aws:wafv2:us-east-1:111111111111:global/webacl/example/12345678-1111-2222-3333-123456789012"
  }

  assert {
    condition     = aws_cloudfront_distribution.backend.web_acl_id == "arn:aws:wafv2:us-east-1:111111111111:global/webacl/example/12345678-1111-2222-3333-123456789012"
    error_message = "Backend distribution should attach the requested Web ACL ARN."
  }
}
