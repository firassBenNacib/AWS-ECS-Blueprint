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
      cidr_block = "10.40.0.0/16"
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
  app_runtime_mode                         = "single_backend"
  environment_domain                       = "example.com"
  route53_zone_id                          = "ZTEST123456"
  bucket_name                              = "example-app-nonprod-frontend"
  cloudfront_logs_bucket_name              = "example-app-nonprod-cloudfront-logs"
  rds_username                             = "admin"
  acm_cert_frontend                        = "arn:aws:acm:us-east-1:123456789012:certificate/frontend-test"
  alb_certificate_arn                      = "arn:aws:acm:eu-west-1:123456789012:certificate/alb-test"
  backend_cache_policy_id                  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  backend_origin_request_policy_id         = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  backend_container_image                  = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/app-backend-nonprod@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  enable_origin_auth_header                = false
  enable_security_baseline                 = false
  enable_account_security_controls         = false
  enable_aws_config                        = false
  enable_inspector                         = false
  enable_rds_master_user_password_rotation = false
  availability_zones                       = ["eu-west-1a", "eu-west-1b"]
  public_app_subnet_cidrs                  = ["10.40.1.0/24", "10.40.2.0/24"]
  private_app_subnet_cidrs                 = ["10.40.21.0/24", "10.40.22.0/24"]
  private_db_subnet_cidrs                  = ["10.40.11.0/24", "10.40.12.0/24"]
}

run "nonprod_root_can_model_the_low_cost_profile" {
  command = plan

  variables {
    private_app_nat_mode         = "canary"
    rds_multi_az                 = false
    enable_managed_waf           = false
    enable_aws_backup            = false
    frontend_runtime_mode        = "s3"
    enable_budget_alerts         = true
    budget_alert_email_addresses = ["ops@example.com"]
    budget_total_monthly_limit   = 150
    enable_operational_alarms    = true
  }

  assert {
    condition     = local.contract_tags["Deployment"] == "nonprod-app"
    error_message = "The nonprod root should stamp the expected deployment tag."
  }

  assert {
    condition     = module.app.effective_private_app_nat_mode == "canary"
    error_message = "The nonprod root should support the one-NAT low-cost profile."
  }

  assert {
    condition     = module.app.managed_waf_enabled == false && module.app.aws_backup_enabled == false
    error_message = "The nonprod low-cost profile should allow WAF and AWS Backup to be disabled."
  }

  assert {
    condition     = module.app.rds_multi_az_enabled == false
    error_message = "The nonprod low-cost profile should allow single-AZ RDS."
  }

  assert {
    condition     = module.app.budget_names["total"] == "example-app-nonprod-total-monthly-cost"
    error_message = "The nonprod root should wire budget alert names through the composition module."
  }

  assert {
    condition     = module.app.operational_alarm_names["alb_target_5xx"] == "example-app-nonprod-alb-target-5xx"
    error_message = "The nonprod root should wire operational alarm names through the composition module."
  }

  assert {
    condition     = module.app.representative_resource_tags["vpc"]["Deployment"] == "nonprod-app" && module.app.representative_resource_tags["vpc"]["ManagedBy"] == "Terraform"
    error_message = "The nonprod root should apply contract tags to the primary-region VPC."
  }

  assert {
    condition     = module.app.representative_resource_tags["rds"]["Environment"] == "nonprod"
    error_message = "The nonprod root should apply the environment tag to the RDS instance."
  }

  assert {
    condition     = module.app.representative_resource_tags["frontend_distribution"]["Deployment"] == "nonprod-app"
    error_message = "The nonprod root should carry contract tags through the us-east-1 CloudFront path."
  }

}

run "nonprod_root_cost_optimized_dev_tier_still_overrides_contracts" {
  command = plan

  variables {
    environment_domain             = "dev.example.com"
    enable_cost_optimized_dev_tier = true
    private_app_nat_mode           = "canary"
    enable_managed_waf             = true
    enable_aws_backup              = true
    rds_multi_az                   = true
    allowed_image_registries       = ["123456789012.dkr.ecr.eu-west-1.amazonaws.com/app-backend-dev"]
    backend_container_image        = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/app-backend-dev@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  assert {
    condition     = module.app.cost_optimized_dev_tier_enabled == true
    error_message = "The nonprod root should expose the cost-optimized dev tier signal."
  }

  assert {
    condition     = module.app.effective_private_app_nat_mode == "disabled"
    error_message = "The cost-optimized dev tier should override the requested NAT mode."
  }

  assert {
    condition     = module.app.managed_waf_enabled == false && module.app.aws_backup_enabled == false
    error_message = "The cost-optimized dev tier should override WAF and AWS Backup to disabled."
  }
}
