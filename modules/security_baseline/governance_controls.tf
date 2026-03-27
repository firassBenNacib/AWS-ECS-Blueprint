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

resource "aws_cloudwatch_event_rule" "ecs_exec_invocations" {
  count = var.enable_ecs_exec_audit_alerts ? 1 : 0

  name        = "${local.prefix}-ecs-exec-invocations"
  description = "Route ECS Exec shell access events to security notifications."

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ecs.amazonaws.com"]
      eventName   = ["ExecuteCommand"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ecs_exec_invocations_sns" {
  count = var.enable_ecs_exec_audit_alerts ? 1 : 0

  rule = aws_cloudwatch_event_rule.ecs_exec_invocations[0].name
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
