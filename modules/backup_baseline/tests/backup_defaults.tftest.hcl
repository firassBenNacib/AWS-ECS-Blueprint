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
  name_prefix = "platform"
}

run "default_backup_plan_and_vaults_exist" {
  command = plan

  assert {
    condition     = length(aws_backup_vault.primary) == 1
    error_message = "Primary backup vault should be created by default."
  }

  assert {
    condition     = length(aws_backup_vault.dr) == 1
    error_message = "DR backup vault should be created when cross-region copy is enabled."
  }

  assert {
    condition     = length(aws_backup_selection.this) == 0
    error_message = "Backup selection should remain opt-in."
  }
}

run "backup_selection_can_be_enabled" {
  command = plan

  variables {
    enable_backup_selection = true
    backup_resource_arns    = ["arn:aws:rds:eu-west-1:123456789012:db:test-db"]
  }

  assert {
    condition     = length(aws_backup_selection.this) == 1
    error_message = "Backup selection should be created when enabled."
  }
}

run "backup_can_be_disabled" {
  command = plan

  variables {
    enable_aws_backup = false
  }

  assert {
    condition     = length(aws_backup_vault.primary) == 0
    error_message = "Primary backup vault should not be created when AWS Backup is disabled."
  }

  assert {
    condition     = length(aws_backup_plan.this) == 0
    error_message = "Backup plan should not be created when AWS Backup is disabled."
  }
}
