resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = var.buckets.cloudfront_logs_bucket_name
  force_destroy = var.buckets.force_destroy
}

resource "aws_s3_bucket_notification" "cloudfront_logs_eventbridge" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  #checkov:skip=CKV2_AWS_65: CloudFront standard log delivery requires ACL-compatible ownership mode.
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms.s3_primary_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  count = var.logging.enable_cloudfront_logs_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "cloudfront-log-retention"
    status = "Enabled"

    expiration {
      days = var.logging.cloudfront_logs_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.logging.cloudfront_logs_abort_incomplete_multipart_upload_days
    }
  }
}

resource "aws_s3_bucket_logging" "cloudfront_logs" {
  count = var.logging.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.cloudfront_logs.id
  target_bucket = aws_s3_bucket.s3_access_logs.id
  target_prefix = "s3-access/cloudfront-logs/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_bucket]
}

resource "aws_s3_bucket" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket        = var.buckets.cloudfront_logs_dr_bucket_name
  force_destroy = var.buckets.force_destroy
}

resource "aws_s3_bucket_notification" "cloudfront_logs_dr_eventbridge" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms.s3_dr_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  rule {
    id     = "cloudfront-logs-dr-lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "cloudfront_logs_dr" {
  provider = aws.dr
  count    = var.logging.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.cloudfront_logs_dr.id
  target_bucket = aws_s3_bucket.s3_access_logs_dr.id
  target_prefix = "s3-access/cloudfront-logs-dr/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_dr_bucket]
}

data "aws_iam_policy_document" "cloudfront_logs_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudfront_logs_replication" {
  name = var.environment.enable_suffix ? "s3-cf-logs-repl-${var.environment.name}" : "s3-cf-logs-repl"

  assume_role_policy = data.aws_iam_policy_document.cloudfront_logs_replication_assume_role.json
}

data "aws_iam_policy_document" "cloudfront_logs_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.cloudfront_logs.arn]
  }

  statement {
    sid = "SourceObjectReadForReplication"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = ["${aws_s3_bucket.cloudfront_logs.arn}/*"]
  }

  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.cloudfront_logs_dr.arn}/*"]
  }

  statement {
    sid = "AllowKmsOnSourceAndDestinationKeys"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]
    resources = [
      var.kms.s3_primary_kms_key_arn,
      var.kms.s3_dr_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "cloudfront_logs_replication" {
  name   = var.environment.enable_suffix ? "s3-cf-logs-repl-${var.environment.name}" : "s3-cf-logs-repl"
  role   = aws_iam_role.cloudfront_logs_replication.id
  policy = data.aws_iam_policy_document.cloudfront_logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  role   = aws_iam_role.cloudfront_logs_replication.arn

  rule {
    id     = "cloudfront-logs-to-dr"
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
      bucket        = aws_s3_bucket.cloudfront_logs_dr.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.kms.s3_dr_kms_key_arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.cloudfront_logs,
    aws_s3_bucket_versioning.cloudfront_logs_dr,
    aws_iam_role_policy.cloudfront_logs_replication
  ]
}
