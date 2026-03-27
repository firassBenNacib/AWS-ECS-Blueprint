locals {
  master_user_secret_rotation_enabled = try(var.data.manage_master_user_password_rotation, false)
  rotation_subnet_ids                 = distinct(compact(try(var.data.rotation_subnet_ids, [])))
  rotation_security_group_ids         = distinct(compact(try(var.data.rotation_security_group_ids, [])))
  master_user_secret_rotation_notification_topic_name = substr(
    "${var.data.identifier}-${var.environment.name}-rds-master-secret-rotation-events",
    0,
    256
  )
  master_user_secret_rotation_stack_name = substr(
    "${var.data.identifier}-${var.environment.name}-rds-master-secret-rotation",
    0,
    128
  )
  master_user_secret_rotation_lambda_name = substr(
    "${var.data.identifier}-${var.environment.name}-rds-master-secret-rotation-fn",
    0,
    64
  )
  master_user_secret_rotation_notification_topic_arn = local.master_user_secret_rotation_enabled ? coalesce(
    try(var.data.stack_notification_topic_arn, null),
    try(aws_sns_topic.master_user_secret_rotation[0].arn, null)
  ) : null
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "master_user_secret_rotation" {
  count = local.master_user_secret_rotation_enabled && try(var.data.stack_notification_topic_arn, null) == null ? 1 : 0

  name              = local.master_user_secret_rotation_notification_topic_name
  kms_master_key_id = try(var.data.notification_topic_kms_key_arn, null)
}

data "aws_iam_policy_document" "master_user_secret_rotation_notifications" {
  count = length(aws_sns_topic.master_user_secret_rotation) > 0 ? 1 : 0

  statement {
    sid    = "AllowCloudFormationPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudformation.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.master_user_secret_rotation[0].arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "master_user_secret_rotation_notifications" {
  count = length(aws_sns_topic.master_user_secret_rotation) > 0 ? 1 : 0

  arn    = aws_sns_topic.master_user_secret_rotation[0].arn
  policy = data.aws_iam_policy_document.master_user_secret_rotation_notifications[0].json
}

resource "aws_cloudformation_stack" "master_user_secret_rotation" {
  count = local.master_user_secret_rotation_enabled ? 1 : 0

  name         = local.master_user_secret_rotation_stack_name
  capabilities = ["CAPABILITY_AUTO_EXPAND", "CAPABILITY_IAM"]
  notification_arns = [
    local.master_user_secret_rotation_notification_topic_arn
  ]

  parameters = {
    SecretArn              = module.rds.master_user_secret_arn
    RotationLambdaName     = local.master_user_secret_rotation_lambda_name
    VpcSubnetIds           = join(",", local.rotation_subnet_ids)
    VpcSecurityGroupIds    = join(",", local.rotation_security_group_ids)
    AutomaticallyAfterDays = tostring(var.data.master_user_password_rotation_automatically_after_days)
  }

  template_body = <<-YAML
    AWSTemplateFormatVersion: '2010-09-09'
    Transform: AWS::SecretsManager-2020-07-23
    Parameters:
      SecretArn:
        Type: String
      RotationLambdaName:
        Type: String
      VpcSubnetIds:
        Type: String
      VpcSecurityGroupIds:
        Type: String
      AutomaticallyAfterDays:
        Type: Number
    Resources:
      RotationSchedule:
        Type: AWS::SecretsManager::RotationSchedule
        Properties:
          SecretId: !Ref SecretArn
          HostedRotationLambda:
            RotationType: MySQLSingleUser
            RotationLambdaName: !Ref RotationLambdaName
            VpcSubnetIds: !Ref VpcSubnetIds
            VpcSecurityGroupIds: !Ref VpcSecurityGroupIds
          RotateImmediatelyOnUpdate: false
          RotationRules:
            AutomaticallyAfterDays: !Ref AutomaticallyAfterDays
    Outputs:
      RotationScheduleId:
        Value: !Ref RotationSchedule
  YAML

  lifecycle {
    precondition {
      condition     = length(local.rotation_subnet_ids) > 0
      error_message = "rotation_subnet_ids must include at least one private app subnet when RDS master secret rotation is enabled."
    }

    precondition {
      condition     = length(local.rotation_security_group_ids) > 0
      error_message = "rotation_security_group_ids must include at least one security group when RDS master secret rotation is enabled."
    }

    precondition {
      condition     = local.master_user_secret_rotation_notification_topic_arn != null
      error_message = "A stack notification SNS topic ARN must be available when RDS master secret rotation is enabled."
    }

    precondition {
      condition     = try(var.data.stack_notification_topic_arn, null) != null || try(var.data.notification_topic_kms_key_arn, null) != null
      error_message = "A customer-managed KMS key ARN must be available for the fallback stack notification SNS topic when no external stack_notification_topic_arn is supplied."
    }
  }

  depends_on = [aws_sns_topic_policy.master_user_secret_rotation_notifications]
}
