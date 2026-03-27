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
