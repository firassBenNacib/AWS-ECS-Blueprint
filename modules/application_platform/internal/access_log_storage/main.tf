data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "s3_access_logs" { #tfsec:ignore:aws-s3-enable-bucket-logging Dedicated access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  #checkov:skip=CKV_AWS_18: Dedicated access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  bucket        = var.buckets.s3_access_logs_bucket_name
  force_destroy = var.buckets.force_destroy
}

resource "aws_s3_bucket_notification" "s3_access_logs_eventbridge" {
  bucket = aws_s3_bucket.s3_access_logs.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms.s3_primary_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    id     = "s3-access-log-retention"
    status = "Enabled"

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket" "s3_access_logs_dr" { #tfsec:ignore:aws-s3-enable-bucket-logging Dedicated DR access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  provider = aws.dr
  #checkov:skip=CKV_AWS_18: Dedicated DR access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  bucket        = var.buckets.s3_access_logs_dr_bucket_name
  force_destroy = var.buckets.force_destroy
}

resource "aws_s3_bucket_notification" "s3_access_logs_dr_eventbridge" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms.s3_dr_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  rule {
    id     = "s3-access-log-retention-dr"
    status = "Enabled"

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "s3_access_logs_dr_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_access_logs_dr.arn,
      "${aws_s3_bucket.s3_access_logs_dr.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowS3ServerAccessLogsDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.s3_access_logs_dr.arn}/s3-access/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = compact([
        var.source_arns.frontend_dr_bucket_arn,
        aws_s3_bucket.cloudfront_logs_dr.arn,
        aws_s3_bucket.alb_access_logs_dr.arn
      ])
    }
  }
}

resource "aws_s3_bucket_policy" "s3_access_logs_dr_bucket" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id
  policy   = data.aws_iam_policy_document.s3_access_logs_dr_bucket_policy.json
}

data "aws_iam_policy_document" "s3_access_logs_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_access_logs_replication" {
  name               = var.environment.enable_suffix ? "s3-access-logs-repl-${var.environment.name}" : "s3-access-logs-repl"
  assume_role_policy = data.aws_iam_policy_document.s3_access_logs_replication_assume_role.json
}

data "aws_iam_policy_document" "s3_access_logs_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.s3_access_logs.arn]
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
    resources = ["${aws_s3_bucket.s3_access_logs.arn}/*"]
  }

  #tfsec:ignore:aws-iam-no-policy-wildcards S3 replication requires object ARN wildcards to cover all keys in the destination bucket.
  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.s3_access_logs_dr.arn}/*"]
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

resource "aws_iam_role_policy" "s3_access_logs_replication" {
  name   = var.environment.enable_suffix ? "s3-access-logs-repl-${var.environment.name}" : "s3-access-logs-repl"
  role   = aws_iam_role.s3_access_logs_replication.id
  policy = data.aws_iam_policy_document.s3_access_logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id
  role   = aws_iam_role.s3_access_logs_replication.arn

  rule {
    id     = "s3-access-logs-to-dr"
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
      bucket        = aws_s3_bucket.s3_access_logs_dr.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.kms.s3_dr_kms_key_arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.s3_access_logs,
    aws_s3_bucket_versioning.s3_access_logs_dr,
    aws_iam_role_policy.s3_access_logs_replication
  ]
}

data "aws_iam_policy_document" "s3_access_logs_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_access_logs.arn,
      "${aws_s3_bucket.s3_access_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowS3ServerAccessLogsDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.s3_access_logs.arn}/s3-access/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = compact([
        var.source_arns.frontend_primary_bucket_arn,
        aws_s3_bucket.alb_access_logs.arn,
        aws_s3_bucket.cloudfront_logs.arn
      ])
    }
  }
}

resource "aws_s3_bucket_policy" "s3_access_logs_bucket" {
  bucket = aws_s3_bucket.s3_access_logs.id
  policy = data.aws_iam_policy_document.s3_access_logs_bucket_policy.json
}
