locals {
  s3_encryption_algorithm = "aws:kms"
  access_logging_enabled  = var.enable_access_logging
  replication_enabled     = var.enable_replication
}

resource "aws_s3_bucket" "frontend" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_notification" "frontend_eventbridge" {
  bucket = aws_s3_bucket.frontend.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "frontend_ownership" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_encryption" {
  #tfsec:ignore:aws-s3-encryption-customer-key Baseline enforces SSE-KMS; customer-managed key remains optional.
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.s3_encryption_algorithm
      kms_master_key_id = var.kms_key_id
    }
  }
}

resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    # Keep the input for backward compatibility, but always enforce versioning.
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_public_block" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "terraform_data" "access_logging_prerequisites" {
  count = local.access_logging_enabled ? 1 : 0

  input = var.access_logging_prerequisite_ids
}

resource "aws_s3_bucket_logging" "frontend" {
  count = local.access_logging_enabled ? 1 : 0

  bucket        = aws_s3_bucket.frontend.id
  target_bucket = var.access_logging_target_bucket_name
  target_prefix = var.access_logging_target_prefix

  depends_on = [terraform_data.access_logging_prerequisites]
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend_lifecycle" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "default-lifecycle"
    status = "Enabled"

    dynamic "expiration" {
      for_each = var.lifecycle_expiration_days != null ? [1] : []
      content {
        days = var.lifecycle_expiration_days
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.lifecycle_noncurrent_expiration_days != null ? [1] : []
      content {
        noncurrent_days = var.lifecycle_noncurrent_expiration_days
      }
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.lifecycle_abort_incomplete_multipart_upload_days
    }
  }
}

resource "terraform_data" "replication_prerequisites" {
  count = local.replication_enabled ? 1 : 0

  input = var.replication_prerequisite_ids
}

resource "aws_s3_bucket_replication_configuration" "frontend" {
  count = local.replication_enabled ? 1 : 0

  bucket = aws_s3_bucket.frontend.id
  role   = var.replication_role_arn

  rule {
    id     = "frontend-to-dr"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = var.replication_destination_bucket_arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.replication_replica_kms_key_id
      }
    }
  }

  depends_on = [
    terraform_data.replication_prerequisites,
    aws_s3_bucket_versioning.frontend_versioning
  ]
}
