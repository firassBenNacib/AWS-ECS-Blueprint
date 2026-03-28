mock_provider "aws" {}

variables {
  bucket_name = "test-frontend-bucket"
}

run "public_access_blocked_by_default" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.frontend_public_block.block_public_acls == true
    error_message = "S3 bucket should block public ACLs by default."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.frontend_public_block.block_public_policy == true
    error_message = "S3 bucket should block public policy by default."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.frontend_public_block.ignore_public_acls == true
    error_message = "S3 bucket should ignore public ACLs by default."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.frontend_public_block.restrict_public_buckets == true
    error_message = "S3 bucket should restrict public buckets by default."
  }
}

run "versioning_enabled_by_default" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.frontend_versioning.versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning should be enabled by default."
  }
}

run "versioning_enabled_even_when_compat_input_is_false" {
  command = plan

  variables {
    versioning_enabled = false
  }

  assert {
    condition     = aws_s3_bucket_versioning.frontend_versioning.versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning should remain enabled when the deprecated compatibility input is false."
  }
}

run "bucket_owner_enforced" {
  command = plan

  assert {
    condition     = aws_s3_bucket_ownership_controls.frontend_ownership.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "S3 bucket should enforce BucketOwnerEnforced ownership."
  }
}

run "force_destroy_disabled_by_default" {
  command = plan

  assert {
    condition     = aws_s3_bucket.frontend.force_destroy == false
    error_message = "S3 force_destroy should be false by default for production safety."
  }
}

run "eventbridge_notifications_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_notification.frontend_eventbridge.eventbridge == true
    error_message = "S3 bucket should have EventBridge notifications enabled."
  }
}

run "lifecycle_disabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.frontend_lifecycle) == 0
    error_message = "S3 lifecycle should not be created when enable_lifecycle is false."
  }
}

run "replication_disabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_replication_configuration.frontend) == 0
    error_message = "S3 replication should not be configured when enable_replication is false."
  }
}

run "access_logging_disabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_logging.frontend) == 0
    error_message = "S3 access logging should not be configured when enable_access_logging is false."
  }
}
