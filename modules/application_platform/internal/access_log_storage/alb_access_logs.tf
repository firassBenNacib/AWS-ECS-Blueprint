resource "aws_s3_bucket" "alb_access_logs" {
  #checkov:skip=CKV_AWS_145: ALB access logs only support SSE-S3 on the destination bucket.
  bucket        = var.buckets.alb_access_logs_bucket_name
  force_destroy = var.buckets.force_destroy
}

resource "aws_s3_bucket_notification" "alb_access_logs_eventbridge" {
  bucket = aws_s3_bucket.alb_access_logs.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" { #tfsec:ignore:aws-s3-encryption-customer-key ALB access logs only support SSE-S3 on the destination bucket.
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    id     = "alb-access-log-retention"
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

resource "aws_s3_bucket" "alb_access_logs_dr" { #tfsec:ignore:aws-s3-enable-bucket-logging Dedicated DR ALB access-log sink bucket logs to the DR access-log bucket below.
  provider = aws.dr
  #checkov:skip=CKV_AWS_145: ALB access logs only support SSE-S3 on the destination bucket.
  #checkov:skip=CKV_AWS_18: Dedicated DR ALB access-log sink bucket logs to the DR access-log bucket below.
  bucket        = var.buckets.alb_access_logs_dr_bucket_name
  force_destroy = var.buckets.force_destroy
}

resource "aws_s3_bucket_notification" "alb_access_logs_dr_eventbridge" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs_dr" { #tfsec:ignore:aws-s3-encryption-customer-key ALB access log replicas remain SSE-S3 encrypted because the source service only supports SSE-S3.
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  rule {
    id     = "alb-access-log-retention-dr"
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

data "aws_iam_policy_document" "alb_access_logs_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.alb_access_logs.arn,
      "${aws_s3_bucket.alb_access_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowALBAccessLogsDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.alb_access_logs.arn}/${var.logging.alb_access_logs_path}AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = data.aws_iam_policy_document.alb_access_logs_bucket_policy.json
}

resource "aws_s3_bucket_logging" "alb_access_logs" {
  count = var.logging.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.alb_access_logs.id
  target_bucket = aws_s3_bucket.s3_access_logs.id
  target_prefix = "s3-access/alb-logs/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_bucket]
}

data "aws_iam_policy_document" "alb_access_logs_dr_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.alb_access_logs_dr.arn,
      "${aws_s3_bucket.alb_access_logs_dr.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id
  policy   = data.aws_iam_policy_document.alb_access_logs_dr_bucket_policy.json
}

resource "aws_s3_bucket_logging" "alb_access_logs_dr" {
  provider = aws.dr
  count    = var.logging.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.alb_access_logs_dr.id
  target_bucket = aws_s3_bucket.s3_access_logs_dr.id
  target_prefix = "s3-access/alb-logs-dr/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_dr_bucket]
}

data "aws_iam_policy_document" "alb_access_logs_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "alb_access_logs_replication" {
  name               = var.environment.enable_suffix ? "s3-alb-logs-repl-${var.environment.name}" : "s3-alb-logs-repl"
  assume_role_policy = data.aws_iam_policy_document.alb_access_logs_replication_assume_role.json
}

data "aws_iam_policy_document" "alb_access_logs_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.alb_access_logs.arn]
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
    resources = ["${aws_s3_bucket.alb_access_logs.arn}/*"]
  }

  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.alb_access_logs_dr.arn}/*"]
  }
}

resource "aws_iam_role_policy" "alb_access_logs_replication" {
  name   = var.environment.enable_suffix ? "s3-alb-logs-repl-${var.environment.name}" : "s3-alb-logs-repl"
  role   = aws_iam_role.alb_access_logs_replication.id
  policy = data.aws_iam_policy_document.alb_access_logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  role   = aws_iam_role.alb_access_logs_replication.arn

  rule {
    id     = "alb-access-logs-to-dr"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.alb_access_logs_dr.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.alb_access_logs,
    aws_s3_bucket_versioning.alb_access_logs_dr,
    aws_iam_role_policy.alb_access_logs_replication
  ]
}
