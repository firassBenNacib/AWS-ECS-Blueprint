mock_provider "aws" {}

variables {
  vpc_id                = "vpc-12345678"
  alb_subnet_ids        = ["subnet-11111111", "subnet-22222222"]
  alb_security_group_id = "sg-12345678"
  certificate_arn       = "arn:aws:acm:eu-west-1:111111111111:certificate/example"
  access_logs_bucket    = "alb-access-logs-bucket"
}

run "internal_by_default" {
  command = plan

  assert {
    condition     = aws_lb.this.internal == true
    error_message = "ALB should remain internal by default."
  }
}

run "public_when_requested" {
  command = plan

  variables {
    internal = false
  }

  assert {
    condition     = aws_lb.this.internal == false
    error_message = "ALB should become internet-facing when internal=false."
  }
}
