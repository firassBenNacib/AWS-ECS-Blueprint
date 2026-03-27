mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  db_name       = "testdb"
  username      = "admin"
  rds_sg_id     = "sg-12345678"
  db_subnet_ids = ["subnet-11111111", "subnet-22222222"]
}

run "multi_az_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.multi_az == true
    error_message = "RDS should be Multi-AZ by default."
  }
}

run "storage_encrypted_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "RDS storage should be encrypted by default."
  }
}

run "deletion_protection_on_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.deletion_protection == true
    error_message = "RDS deletion protection should be enabled by default."
  }
}

run "skip_final_snapshot_off_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == false
    error_message = "RDS should not skip final snapshot by default."
  }
}

run "managed_master_password_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "RDS should use managed master user password by default."
  }
}

run "publicly_accessible_always_false" {
  command = plan

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "RDS must never be publicly accessible."
  }
}

run "iam_auth_enabled_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled == true
    error_message = "RDS IAM database authentication should be enabled by default."
  }
}

run "copy_tags_to_snapshot_enabled" {
  command = plan

  assert {
    condition     = aws_db_instance.this.copy_tags_to_snapshot == true
    error_message = "RDS should copy tags to snapshots."
  }
}

run "auto_minor_version_upgrade_enabled" {
  command = plan

  assert {
    condition     = aws_db_instance.this.auto_minor_version_upgrade == true
    error_message = "RDS should enable automatic minor version upgrades."
  }
}

run "auto_minor_version_upgrade_can_be_disabled" {
  command = plan

  variables {
    auto_minor_version_upgrade = false
  }

  assert {
    condition     = aws_db_instance.this.auto_minor_version_upgrade == false
    error_message = "RDS should honor auto_minor_version_upgrade overrides."
  }
}

run "enhanced_monitoring_role_created" {
  command = plan

  assert {
    condition     = length(aws_iam_role.enhanced_monitoring) == 1
    error_message = "Enhanced monitoring IAM role should be created when monitoring_interval_seconds > 0."
  }
}

run "environment_suffix_applied" {
  command = plan

  variables {
    enable_environment_suffix = true
    environment_name_override = "prod"
  }

  assert {
    condition     = aws_db_instance.this.identifier == "app-rds-prod"
    error_message = "RDS identifier should include environment suffix when enabled."
  }
}

run "engine_version_can_be_overridden" {
  command = plan

  variables {
    engine_version = "8.0.41"
  }

  assert {
    condition     = aws_db_instance.this.engine_version == "8.0.41"
    error_message = "RDS engine version override should be honored."
  }
}
