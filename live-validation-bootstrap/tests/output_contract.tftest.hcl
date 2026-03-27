mock_provider "aws" {
  mock_resource "aws_ssm_parameter" {
    override_during = plan
    defaults = {
      name = "/example-app/live-validation/current"
    }
  }

  mock_resource "aws_route53_record" {
    override_during = plan
    defaults = {
      fqdn = "_validation.example.com"
    }
  }

  mock_resource "aws_acm_certificate" {
    override_during = plan
    defaults = {
      arn = "arn:aws:acm:eu-west-1:123456789012:certificate/test"
      domain_validation_options = [
        {
          domain_name           = "example.com"
          resource_record_name  = "_validation.example.com"
          resource_record_value = "_token.acm-validations.aws."
          resource_record_type  = "CNAME"
        }
      ]
    }
  }

  mock_resource "aws_acm_certificate_validation" {
    override_during = plan
    defaults = {
      certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/validated"
    }
  }
}

mock_provider "aws" {
  alias = "us_east_1"

  mock_resource "aws_acm_certificate" {
    override_during = plan
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
      domain_validation_options = [
        {
          domain_name           = "example.com"
          resource_record_name  = "_validation.example.com"
          resource_record_value = "_token.acm-validations.aws."
          resource_record_type  = "CNAME"
        }
      ]
    }
  }

  mock_resource "aws_acm_certificate_validation" {
    override_during = plan
    defaults = {
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/validated"
    }
  }
}

mock_provider "random" {
  mock_resource "random_password" {
    override_during = plan
    defaults = {
      result = "validationoriginsecret"
    }
  }
}

variables {
  project_name                 = "example-app"
  aws_region                   = "eu-west-1"
  environment_domain           = "example.com"
  route53_zone_id              = "ZTEST123456"
  prod_validation_dns_label    = "lv-prod"
  nonprod_validation_dns_label = "lv-nonprod"
}

run "generated_tfvars_exclude_removed_backend_geo_input" {
  command = plan

  assert {
    condition     = !strcontains(nonsensitive(output.live_validation_tfvars_prod_app), "backend_geo_restriction_type")
    error_message = "Generated live-validation tfvars must not include the removed backend_geo_restriction_type input."
  }

  assert {
    condition     = strcontains(nonsensitive(output.live_validation_tfvars_nonprod_app), "frontend_geo_restriction_type   = \"none\"")
    error_message = "Generated live-validation tfvars should keep the frontend geo restriction input."
  }
}
