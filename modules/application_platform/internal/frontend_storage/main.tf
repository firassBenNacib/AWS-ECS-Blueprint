module "s3" {
  count  = var.frontend.runtime_is_s3 ? 1 : 0
  source = "../../../s3"

  bucket_name                                      = var.frontend.bucket_name
  force_destroy                                    = var.frontend.force_destroy
  versioning_enabled                               = var.frontend.versioning_enabled
  enable_kms_encryption                            = var.frontend.enable_kms_encryption
  kms_key_id                                       = var.frontend.primary_kms_key_arn
  enable_access_logging                            = var.frontend.enable_access_logging
  access_logging_target_bucket_name                = var.frontend.enable_access_logging ? var.frontend.primary_access_logging_target_bucket_name : null
  access_logging_target_prefix                     = var.frontend.primary_access_logging_target_prefix
  access_logging_prerequisite_ids                  = var.frontend.enable_access_logging ? [var.frontend.primary_access_logging_prerequisite_id] : []
  enable_replication                               = true
  replication_role_arn                             = aws_iam_role.frontend_replication[0].arn
  replication_destination_bucket_arn               = aws_s3_bucket.frontend_dr[0].arn
  replication_replica_kms_key_id                   = var.frontend.dr_kms_key_arn
  replication_prerequisite_ids                     = [aws_s3_bucket_versioning.frontend_dr[0].id, aws_iam_role_policy.frontend_replication[0].id]
  enable_lifecycle                                 = var.frontend.enable_lifecycle
  lifecycle_expiration_days                        = var.frontend.lifecycle_expiration_days
  lifecycle_noncurrent_expiration_days             = var.frontend.lifecycle_noncurrent_expiration_days
  lifecycle_abort_incomplete_multipart_upload_days = var.frontend.lifecycle_abort_incomplete_multipart_upload_days
}

resource "aws_s3_bucket" "frontend_dr" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr
  #checkov:skip=CKV_AWS_144: Destination bucket in the frontend CRR topology; Checkov can miss the module-owned source replication association.
  bucket        = var.frontend.dr_bucket_name
  force_destroy = var.frontend.force_destroy
}

resource "aws_s3_bucket_notification" "frontend_dr_eventbridge" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr[0].id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "frontend_dr" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_dr" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.frontend.dr_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "frontend_dr" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_dr" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend_dr" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr[0].id

  rule {
    id     = "frontend-dr-lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "frontend_dr" {
  count         = var.frontend.runtime_is_s3 && var.frontend.enable_access_logging ? 1 : 0
  provider      = aws.dr
  bucket        = aws_s3_bucket.frontend_dr[0].id
  target_bucket = var.frontend.dr_access_logging_target_bucket_name
  target_prefix = "s3-access/frontend-dr/"

  depends_on = [terraform_data.frontend_dr_access_logging_prerequisite[0]]
}

resource "terraform_data" "frontend_dr_access_logging_prerequisite" {
  count = var.frontend.runtime_is_s3 && var.frontend.enable_access_logging ? 1 : 0
  input = var.frontend.dr_access_logging_prerequisite_id
}

data "aws_iam_policy_document" "frontend_replication_assume_role" {
  count = var.frontend.runtime_is_s3 ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "frontend_replication" {
  count = var.frontend.runtime_is_s3 ? 1 : 0

  name               = var.environment.enable_suffix ? "s3-frontend-replication-${var.environment.name}" : "s3-frontend-replication"
  assume_role_policy = data.aws_iam_policy_document.frontend_replication_assume_role[0].json
}

data "aws_iam_policy_document" "frontend_replication" {
  count = var.frontend.runtime_is_s3 ? 1 : 0

  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.s3[0].bucket_arn]
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
    resources = ["${module.s3[0].bucket_arn}/*"]
  }

  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.frontend_dr[0].arn}/*"]
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
      var.frontend.primary_kms_key_arn,
      var.frontend.dr_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "frontend_replication" {
  count  = var.frontend.runtime_is_s3 ? 1 : 0
  name   = var.environment.enable_suffix ? "s3-frontend-replication-${var.environment.name}" : "s3-frontend-replication"
  role   = aws_iam_role.frontend_replication[0].id
  policy = data.aws_iam_policy_document.frontend_replication[0].json
}
