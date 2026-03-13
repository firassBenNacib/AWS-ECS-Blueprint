data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_region" "dr" {
  provider = aws.dr
}

locals {
  prefix                          = lower(replace(var.name_prefix, "_", "-"))
  cloudtrail_name                 = "${local.prefix}-trail"
  config_recorder_name            = "${local.prefix}-config-recorder"
  config_role_name                = "${local.prefix}-config-role"
  access_analyzer_name            = "${local.prefix}-access-analyzer"
  cloudwatch_logs_service         = "logs.${data.aws_region.current.region}.amazonaws.com"
  baseline_kms_key_arn            = aws_kms_key.cloudtrail.arn
  log_bucket_dr_suffix            = "-dr-${data.aws_region.dr.region}"
  log_bucket_dr_name_final        = var.log_bucket_dr_name != null && trimspace(var.log_bucket_dr_name) != "" ? trimspace(var.log_bucket_dr_name) : "${substr(var.log_bucket_name, 0, 63 - length(local.log_bucket_dr_suffix))}${local.log_bucket_dr_suffix}"
  log_bucket_dr_kms_key_arn       = aws_kms_key.logs_dr.arn
  managed_security_findings_topic = var.security_findings_sns_topic_arn == null || trimspace(var.security_findings_sns_topic_arn) == ""
  security_findings_topic_arn     = local.managed_security_findings_topic ? aws_sns_topic.security_findings[0].arn : trimspace(var.security_findings_sns_topic_arn)
  security_findings_event_rule_arns = compact([
    aws_cloudwatch_event_rule.guardduty_high_critical.arn,
    try(aws_cloudwatch_event_rule.securityhub_high_critical[0].arn, null)
  ])
}

data "aws_iam_policy_document" "cloudtrail_kms" {
  #checkov:skip=CKV_AWS_109: KMS key policies require account-root administration permissions on resource *.
  #checkov:skip=CKV_AWS_111: KMS key policies require account-root administration permissions on resource *.
  #checkov:skip=CKV_AWS_356: KMS key policy statements must use resource * and cannot be narrowed to specific key ARNs.
  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
      ]
    }
  }

  statement {
    sid    = "AllowConfigUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogsUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = [local.cloudwatch_logs_service]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowSNSUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowS3ReplicationRoleUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.logs_replication.arn]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = local.managed_security_findings_topic ? [1] : []
    content {
      sid    = "AllowEventBridgeUseOfTheKey"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }

      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_kms_key" "cloudtrail" {
  description             = "KMS CMK for security baseline CloudTrail and logging encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.cloudtrail_kms.json
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${local.prefix}-security-baseline"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

data "aws_iam_policy_document" "logs_dr_kms" {
  #checkov:skip=CKV_AWS_109: KMS key policies require account-root administration permissions on resource *.
  #checkov:skip=CKV_AWS_111: KMS key policies require account-root administration permissions on resource *.
  #checkov:skip=CKV_AWS_356: KMS key policy statements must use resource * and cannot be narrowed to specific key ARNs.
  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowS3ReplicationRoleUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.logs_replication.arn]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "logs_dr" {
  provider = aws.dr

  description             = "KMS CMK for DR security baseline log bucket replication"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.logs_dr_kms.json
}

resource "aws_kms_alias" "logs_dr" {
  provider = aws.dr

  name          = "alias/${local.prefix}-security-baseline-dr"
  target_key_id = aws_kms_key.logs_dr.key_id
}

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

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${local.cloudtrail_name}"
  retention_in_days = var.cloudtrail_retention_days
  kms_key_id        = local.baseline_kms_key_arn
}

data "aws_iam_policy_document" "cloudtrail_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name               = "${local.prefix}-cloudtrail-cw-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume.json
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" { #tfsec:ignore:aws-iam-no-policy-wildcards CloudWatch Logs stream ARNs require wildcard suffixes and cannot be fully enumerated.
  name = "${local.prefix}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams"
        ]
        Resource = aws_cloudwatch_log_group.cloudtrail.arn
      }
    ]
  })
}

resource "aws_sns_topic" "cloudtrail_notifications" {
  name              = "${local.prefix}-cloudtrail-notifications"
  kms_master_key_id = local.baseline_kms_key_arn
}

data "aws_iam_policy_document" "cloudtrail_sns" {
  statement {
    sid    = "AllowCloudTrailPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["SNS:Publish"]
    resources = [
      aws_sns_topic.cloudtrail_notifications.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "cloudtrail_notifications" {
  arn    = aws_sns_topic.cloudtrail_notifications.arn
  policy = data.aws_iam_policy_document.cloudtrail_sns.json
}

resource "aws_sns_topic" "security_findings" {
  count = local.managed_security_findings_topic ? 1 : 0

  name              = "${local.prefix}-security-findings"
  kms_master_key_id = local.baseline_kms_key_arn
}

data "aws_iam_policy_document" "security_findings_sns" {
  count = local.managed_security_findings_topic ? 1 : 0

  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.security_findings[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = local.security_findings_event_rule_arns
    }
  }
}

resource "aws_sns_topic_policy" "security_findings" {
  count = local.managed_security_findings_topic ? 1 : 0

  arn    = aws_sns_topic.security_findings[0].arn
  policy = data.aws_iam_policy_document.security_findings_sns[0].json
}

resource "aws_sns_topic_subscription" "security_findings" {
  for_each = local.managed_security_findings_topic ? {
    for idx, sub in var.security_findings_sns_subscriptions :
    tostring(idx) => sub
  } : {}

  topic_arn = aws_sns_topic.security_findings[0].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

#checkov:skip=CKV2_AWS_10: CloudWatch integration is configured explicitly with cloud_watch_logs_group_arn and cloud_watch_logs_role_arn.
resource "aws_cloudtrail" "this" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = local.baseline_kms_key_arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_to_cloudwatch.arn
  sns_topic_name                = aws_sns_topic.cloudtrail_notifications.name
  enable_logging                = true

  dynamic "event_selector" {
    for_each = var.enable_cloudtrail_data_events && length(var.cloudtrail_data_event_resources) > 0 ? [1] : []
    content {
      include_management_events = true
      read_write_type           = "All"

      data_resource {
        type   = "AWS::S3::Object"
        values = var.cloudtrail_data_event_resources
      }
    }
  }

  depends_on = [aws_sns_topic_policy.cloudtrail_notifications]
}

data "aws_iam_policy_document" "config_assume" {
  count = var.enable_aws_config ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  count = var.enable_aws_config ? 1 : 0

  name               = local.config_role_name
  assume_role_policy = data.aws_iam_policy_document.config_assume[0].json
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_aws_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_aws_config ? 1 : 0

  name     = local.config_recorder_name
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_aws_config ? 1 : 0

  name           = "${local.prefix}-config-delivery"
  s3_bucket_name = aws_s3_bucket.logs.bucket

  depends_on = [aws_config_configuration_recorder.this]
}

#checkov:skip=CKV2_AWS_45: Recorder is enabled and configured for all supported/global resources in aws_config_configuration_recorder.this.
resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_aws_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0

  enable_default_standards = false
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each = var.enable_security_hub ? toset(var.securityhub_standards) : toset([])

  standards_arn = each.value

  depends_on = [aws_securityhub_account.this]
}

resource "aws_cloudwatch_event_rule" "guardduty_high_critical" {
  name        = "${local.prefix}-guardduty-high-critical"
  description = "Route high/critical GuardDuty findings to security notifications."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        {
          numeric = [">=", 7]
        }
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_high_critical_sns" {
  rule = aws_cloudwatch_event_rule.guardduty_high_critical.name
  arn  = local.security_findings_topic_arn
}

resource "aws_cloudwatch_event_rule" "securityhub_high_critical" {
  count = var.enable_security_hub ? 1 : 0

  name        = "${local.prefix}-securityhub-high-critical"
  description = "Route high/critical Security Hub findings to security notifications."

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["HIGH", "CRITICAL"]
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_high_critical_sns" {
  count = var.enable_security_hub ? 1 : 0

  rule = aws_cloudwatch_event_rule.securityhub_high_critical[0].name
  arn  = local.security_findings_topic_arn
}

resource "aws_accessanalyzer_analyzer" "this" {
  count = var.enable_access_analyzer ? 1 : 0

  analyzer_name = local.access_analyzer_name
  type          = "ACCOUNT"
}

resource "aws_inspector2_enabler" "this" {
  count = var.enable_inspector ? 1 : 0

  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR", "EC2"]
}
