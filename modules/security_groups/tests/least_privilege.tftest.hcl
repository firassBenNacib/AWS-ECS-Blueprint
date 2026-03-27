mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }

  mock_data "aws_ec2_managed_prefix_list" {
    defaults = {
      id = "pl-12345678"
    }
  }
}

variables {
  vpc_id = "vpc-12345678"
}

run "rds_ingress_restricted_to_backend_only" {
  command = plan

  assert {
    condition = length([
      for rule in aws_security_group.rds.ingress : rule
      if rule.from_port == 3306 && rule.to_port == 3306 && rule.protocol == "tcp"
    ]) == 1
    error_message = "RDS security group should allow exactly one TCP ingress rule on port 3306."
  }
}

run "backend_service_ingress_from_alb_only" {
  command = plan

  assert {
    condition = length([
      for rule in aws_security_group.backend_service.ingress : rule
      if rule.from_port == 8080 && rule.to_port == 8080 && rule.protocol == "tcp"
    ]) == 1
    error_message = "Backend service SG should allow exactly one TCP ingress rule on app_port (default 8080)."
  }
}

run "alb_ingress_on_listener_port" {
  command = plan

  assert {
    condition = length([
      for rule in aws_security_group.backend_alb.ingress : rule
      if rule.from_port == 443 && rule.to_port == 443 && rule.protocol == "tcp"
    ]) == 1
    error_message = "ALB SG should allow exactly one TCP ingress rule on listener port (default 443)."
  }
}

run "custom_app_port_propagates" {
  command = plan

  variables {
    app_port = 3000
  }

  assert {
    condition = length([
      for rule in aws_security_group.backend_service.ingress : rule
      if rule.from_port == 3000 && rule.to_port == 3000 && rule.protocol == "tcp"
    ]) == 1
    error_message = "Backend service SG should reflect custom app_port."
  }

  assert {
    condition     = aws_security_group_rule.backend_alb_to_backend_service.from_port == 3000
    error_message = "ALB-to-backend egress rule should reflect custom app_port."
  }

  assert {
    condition     = aws_security_group_rule.backend_service_to_rds.from_port == 3306
    error_message = "Backend-to-RDS egress should always use MySQL port 3306 regardless of app_port."
  }
}

run "environment_suffix_applied" {
  command = plan

  variables {
    enable_environment_suffix = true
    environment_name_override = "staging"
  }

  assert {
    condition     = aws_security_group.backend_alb.name == "backend-alb-sg-staging"
    error_message = "ALB SG name should include environment suffix."
  }

  assert {
    condition     = aws_security_group.backend_service.name == "backend-service-sg-staging"
    error_message = "Backend service SG name should include environment suffix."
  }

  assert {
    condition     = aws_security_group.rds.name == "rds-from-backend-sg-staging"
    error_message = "RDS SG name should include environment suffix."
  }
}
