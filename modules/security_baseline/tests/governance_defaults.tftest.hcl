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

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

mock_provider "aws" {
  alias = "dr"

  mock_data "aws_region" {
    defaults = {
      name   = "us-west-2"
      region = "us-west-2"
    }
  }
}

variables {
  name_prefix     = "platform"
  log_bucket_name = "platform-security-logs"
  securityhub_standards = [
    "arn:aws:securityhub:eu-west-1::standards/aws-foundational-security-best-practices/v/1.0.0"
  ]
}

run "default_governance_controls_exist" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.enable_logging == true
    error_message = "CloudTrail should be enabled by default."
  }

  assert {
    condition     = aws_cloudtrail.this.name == "platform-trail"
    error_message = "CloudTrail should use the expected derived name."
  }

  assert {
    condition     = length(aws_sns_topic.security_findings) == 1
    error_message = "A managed security findings topic should be created by default."
  }
}

run "optional_controls_can_be_disabled" {
  command = plan

  variables {
    enable_aws_config      = false
    enable_security_hub    = false
    enable_access_analyzer = false
    enable_inspector       = false
  }

  assert {
    condition     = length(aws_config_configuration_recorder.this) == 0
    error_message = "AWS Config resources should not be created when disabled."
  }

  assert {
    condition     = length(aws_securityhub_account.this) == 0
    error_message = "Security Hub should not be created when disabled."
  }

  assert {
    condition     = length(aws_accessanalyzer_analyzer.this) == 0
    error_message = "Access Analyzer should not be created when disabled."
  }

  assert {
    condition     = length(aws_inspector2_enabler.this) == 0
    error_message = "Inspector should not be created when disabled."
  }
}

run "ecs_exec_audit_alerts_are_opt_in" {
  command = plan

  variables {
    enable_ecs_exec_audit_alerts = true
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.ecs_exec_invocations) == 1
    error_message = "ECS Exec audit rule should be created when enabled."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.ecs_exec_invocations[0].name == "platform-ecs-exec-invocations"
    error_message = "ECS Exec audit rule should use the expected derived name."
  }
}
