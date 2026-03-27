mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      user_id    = "AIDATEST1234567890"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name   = "eu-west-1"
      region = "eu-west-1"
    }
  }

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

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

mock_provider "aws" {
  alias = "us_east_1"

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name   = "us-east-1"
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

mock_provider "aws" {
  alias = "dr"

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name   = "us-west-2"
      region = "us-west-2"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

mock_provider "null" {}
mock_provider "archive" {}
mock_provider "external" {}

variables {
  project_name                             = "example-app"
  environment_name_override                = "nonprod"
  environment_domain                       = "example.com"
  route53_zone_id                          = "ZTEST123456"
  bucket_name                              = "example-app-nonprod-frontend"
  cloudfront_logs_bucket_name              = "example-app-nonprod-cloudfront-logs"
  rds_username                             = "admin"
  acm_cert_frontend                        = "arn:aws:acm:us-east-1:123456789012:certificate/frontend-test"
  alb_certificate_arn                      = "arn:aws:acm:eu-west-1:123456789012:certificate/alb-test"
  backend_container_image                  = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/app-backend-nonprod@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  enable_origin_auth_header                = false
  enable_security_baseline                 = false
  enable_account_security_controls         = false
  enable_aws_config                        = false
  enable_inspector                         = false
  enable_aws_backup                        = false
  enable_rds_master_user_password_rotation = false
  availability_zones                       = ["eu-west-1a", "eu-west-1b"]
  public_app_subnet_cidrs                  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs                 = ["10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnet_cidrs                  = ["10.0.21.0/24", "10.0.22.0/24"]
}

run "default_s3_profile_uses_private_s3_frontend" {
  command = plan

  assert {
    condition     = module.deployment_contract.frontend_runtime_is_s3 == true
    error_message = "Default frontend runtime mode should remain s3."
  }

  assert {
    condition     = module.deployment_contract.bucket_name_final == "example-app-nonprod-frontend-nonprod"
    error_message = "Default runtime should keep the expected frontend content bucket contract."
  }

  assert {
    condition     = module.deployment_contract.effective_private_app_nat_mode == "required"
    error_message = "Default profile should keep required NAT mode."
  }

  assert {
    condition     = module.deployment_contract.effective_rds_multi_az == true
    error_message = "Default profile should keep Multi-AZ RDS enabled."
  }

  assert {
    condition     = module.edge_contract.frontend_aliases[0] == "nonprod.example.com"
    error_message = "Non-production aliases should include the environment subdomain."
  }
}

run "frontend_ecs_profile_removes_frontend_bucket_path" {
  command = plan

  variables {
    frontend_runtime_mode = "ecs"
  }

  assert {
    condition     = module.deployment_contract.frontend_runtime_is_s3 == false
    error_message = "Frontend ECS profile should disable the s3 frontend path."
  }

  assert {
    condition     = module.frontend_storage.frontend_primary_bucket_name == null
    error_message = "Frontend ECS profile should not create the frontend content bucket."
  }

  assert {
    condition     = module.edge_contract.frontend_primary_bucket_arn_expected == null
    error_message = "Frontend ECS profile should not expect a frontend S3 origin bucket."
  }
}

run "cost_optimized_dev_tier_changes_effective_runtime_contract" {
  command = plan

  variables {
    environment_name_override      = "dev"
    enable_cost_optimized_dev_tier = true
    backend_container_image        = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/app-backend-dev@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  assert {
    condition     = module.deployment_contract.cost_optimized_dev_tier_enabled == true
    error_message = "Cost-optimized dev tier should report as enabled."
  }

  assert {
    condition     = module.deployment_contract.effective_private_app_nat_mode == "disabled"
    error_message = "Cost-optimized dev tier should disable private-app NAT."
  }

  assert {
    condition     = module.deployment_contract.effective_rds_multi_az == false
    error_message = "Cost-optimized dev tier should force single-AZ RDS."
  }

  assert {
    condition     = module.platform_governance.cloudtrail_arn == null
    error_message = "Cost-optimized dev tier should disable account-level security baseline controls."
  }

  assert {
    condition     = module.deployment_contract.effective_enable_managed_waf == false
    error_message = "Cost-optimized dev tier should disable managed WAF."
  }

  assert {
    condition     = module.deployment_contract.effective_enable_aws_backup == false
    error_message = "Cost-optimized dev tier should disable AWS Backup."
  }

  assert {
    condition     = module.deployment_contract.effective_backend_desired_count == 1 && module.deployment_contract.effective_backend_min_count == 1 && module.deployment_contract.effective_backend_max_count == 1
    error_message = "Cost-optimized dev tier should force single-backend ECS counts to 1/1/1."
  }
}

run "public_alb_restricted_uses_public_edge_subnets_for_alb" {
  command = plan

  variables {
    backend_ingress_mode = "public_alb_restricted"
  }

  assert {
    condition     = module.deployment_contract.backend_ingress_is_public == true
    error_message = "public_alb_restricted should switch the backend ingress contract to public."
  }

  assert {
    condition     = module.deployment_contract.backend_ingress_is_vpc_origin == false
    error_message = "public_alb_restricted should stop using the VPC-origin ALB contract."
  }

  assert {
    condition     = module.edge_contract.route53_zone_id_effective == "ZTEST123456"
    error_message = "The explicit Route53 zone override should be honored."
  }
}

run "budget_alerts_can_be_enabled_for_operability_visibility" {
  command = plan

  variables {
    enable_budget_alerts         = true
    budget_alert_email_addresses = ["ops@example.com"]
    budget_total_monthly_limit   = 250
    budget_rds_monthly_limit     = 80
  }

  assert {
    condition     = module.platform_governance.budget_names["total"] == "example-app-nonprod-total-monthly-cost"
    error_message = "Budget alerts should wire through the governance module with the expected total budget name."
  }

  assert {
    condition     = module.platform_governance.budget_names["rds"] == "example-app-nonprod-rds-monthly-cost"
    error_message = "Budget alerts should wire through the governance module with the expected RDS budget name."
  }
}

run "operational_alarms_can_be_enabled" {
  command = plan

  variables {
    enable_operational_alarms = true
  }

  assert {
    condition     = module.operational_observability.alarm_names["alb_target_5xx"] == "example-app-nonprod-alb-target-5xx"
    error_message = "Operational alarms should create the expected ALB target 5xx alarm name."
  }

  assert {
    condition     = module.operational_observability.alarm_names["cloudfront_5xx_rate_high"] == "example-app-nonprod-cloudfront-5xx-rate-high"
    error_message = "Operational alarms should create the expected CloudFront 5xx rate alarm name."
  }
}
