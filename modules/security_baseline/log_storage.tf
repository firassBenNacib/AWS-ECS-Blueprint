resource "aws_s3_bucket" "logs" { #tfsec:ignore:aws-s3-enable-bucket-logging Bucket access logging is configured via aws_s3_bucket_logging.logs. #tfsec:ignore:aws-cloudtrail-require-bucket-access-logging A dedicated access-log sink is optional and wired via access_logs_bucket_name when provided.
  bucket              = var.log_bucket_name
  force_destroy       = var.log_bucket_force_destroy
  object_lock_enabled = var.enable_log_bucket_object_lock
}

resource "aws_s3_bucket_object_lock_configuration" "logs" {
  count = var.enable_log_bucket_object_lock ? 1 : 0

  #checkov:skip=CKV2_AWS_62: Object Lock is intentionally enabled in GOVERNANCE mode for CloudTrail immutability. COMPLIANCE mode would prevent destruction during testing.
  bucket = aws_s3_bucket.logs.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.object_lock_days
    }
  }
}

resource "aws_s3_bucket_notification" "logs_eventbridge" {
  bucket = aws_s3_bucket.logs.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.baseline_kms_key_arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "baseline-log-retention"
    status = "Enabled"

    expiration {
      days = var.cloudtrail_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "logs" {
  count = var.access_logs_bucket_name == null ? 0 : 1

  bucket        = aws_s3_bucket.logs.id
  target_bucket = var.access_logs_bucket_name
  target_prefix = "s3-access/security-baseline/"
}

data "aws_iam_policy_document" "logs_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = [1]
    content {
      sid    = "AllowCloudTrailGetBucketAcl"
      effect = "Allow"
      actions = [
        "s3:GetBucketAcl"
      ]

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      resources = [
        aws_s3_bucket.logs.arn
      ]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values = [
          "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = [1]
    content {
      sid    = "AllowCloudTrailWrite"
      effect = "Allow"
      actions = [
        "s3:PutObject"
      ]

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      resources = [
        "${aws_s3_bucket.logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      ]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values = [
          "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = [1]
    content {
      sid    = "AllowConfigGetBucketAclAndList"
      effect = "Allow"
      actions = [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ]

      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }

      resources = [
        aws_s3_bucket.logs.arn
      ]

      condition {
        test     = "StringEquals"
        variable = "AWS:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }

  dynamic "statement" {
    for_each = [1]
    content {
      sid    = "AllowConfigWrite"
      effect = "Allow"
      actions = [
        "s3:PutObject"
      ]

      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }

      resources = [
        "${aws_s3_bucket.logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
      ]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }

      condition {
        test     = "StringEquals"
        variable = "AWS:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket.json
}

resource "aws_s3_bucket" "logs_dr" { #tfsec:ignore:aws-s3-enable-bucket-logging Bucket access logging is configured via aws_s3_bucket_logging.logs_dr when a DR access-log sink is provided.
  provider = aws.dr

  bucket        = local.log_bucket_dr_name_final
  force_destroy = var.log_bucket_force_destroy
}

resource "aws_s3_bucket_notification" "logs_dr_eventbridge" {
  provider = aws.dr

  bucket = aws_s3_bucket.logs_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.logs_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.log_bucket_dr_kms_key_arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.logs_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.logs_dr.id

  rule {
    id     = "baseline-log-retention-dr"
    status = "Enabled"

    expiration {
      days = var.cloudtrail_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "logs_dr" {
  provider = aws.dr
  count    = var.access_logs_bucket_name_dr == null ? 0 : 1

  bucket        = aws_s3_bucket.logs_dr.id
  target_bucket = var.access_logs_bucket_name_dr
  target_prefix = "s3-access/security-baseline-dr/"
}

data "aws_iam_policy_document" "logs_dr_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.logs_dr.arn,
      "${aws_s3_bucket.logs_dr.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.logs_dr.id
  policy = data.aws_iam_policy_document.logs_dr_bucket.json
}

data "aws_iam_policy_document" "logs_replication_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "logs_replication" {
  name               = "${local.prefix}-logs-replication"
  assume_role_policy = data.aws_iam_policy_document.logs_replication_assume.json
}

data "aws_iam_policy_document" "logs_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.logs.arn]
  }

  #tfsec:ignore:aws-iam-no-policy-wildcards S3 replication requires object ARN wildcards to cover all keys in the source bucket.
  statement {
    sid = "SourceObjectReadForReplication"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
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
    resources = ["${aws_s3_bucket.logs_dr.arn}/*"]
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
      local.baseline_kms_key_arn,
      local.log_bucket_dr_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "logs_replication" {
  name   = "${local.prefix}-logs-replication"
  role   = aws_iam_role.logs_replication.id
  policy = data.aws_iam_policy_document.logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  role   = aws_iam_role.logs_replication.arn

  rule {
    id     = "baseline-logs-to-dr"
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
      bucket        = aws_s3_bucket.logs_dr.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = local.log_bucket_dr_kms_key_arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.logs_dr,
    aws_iam_role_policy.logs_replication
  ]
}
