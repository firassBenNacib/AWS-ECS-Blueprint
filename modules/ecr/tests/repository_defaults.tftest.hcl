mock_provider "aws" {}

variables {
  repository_name = "app-backend"
}

run "repository_defaults_harden_images" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "ECR repositories should enforce immutable image tags."
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == true
    error_message = "ECR repositories should enable scan-on-push by default."
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].kms_key == "alias/aws/ecr"
    error_message = "ECR repositories should default to the AWS-managed ECR KMS key."
  }
}

run "custom_kms_key_is_honored" {
  command = plan

  variables {
    encryption_kms_key_arn = "arn:aws:kms:eu-west-1:123456789012:key/abcd1234-abcd-1234-abcd-1234567890ab"
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].kms_key == "arn:aws:kms:eu-west-1:123456789012:key/abcd1234-abcd-1234-abcd-1234567890ab"
    error_message = "Custom ECR KMS keys should override the AWS-managed default."
  }
}

run "lifecycle_policy_uses_requested_retention_count" {
  command = plan

  variables {
    max_image_count = 5
  }

  assert {
    condition     = strcontains(aws_ecr_lifecycle_policy.this.policy, "\"countNumber\":5")
    error_message = "Lifecycle policy should retain the requested max_image_count value."
  }
}
