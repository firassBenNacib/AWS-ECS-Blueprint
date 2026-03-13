data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "dr" {
  provider = aws.dr
}

locals {
  prefix                   = lower(replace(var.name_prefix, "_", "-"))
  backup_vault_name_final  = var.backup_vault_name != null && trimspace(var.backup_vault_name) != "" ? trimspace(var.backup_vault_name) : "${local.prefix}-backup-vault"
  backup_dr_kms_key_arn    = try(aws_kms_key.dr[0].arn, null)
  backup_vault_kms_key_arn = try(aws_kms_key.primary[0].arn, null)
}

data "aws_iam_policy_document" "backup_kms" {
  #checkov:skip=CKV_AWS_109: KMS key policies require account-root administration permissions on resource *.
  #checkov:skip=CKV_AWS_111: KMS key policies require account-root administration permissions on resource *.
  #checkov:skip=CKV_AWS_356: KMS key policy statements must use resource * and cannot be narrowed to a specific key ARN.
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
    sid    = "AllowBackupServiceUseOfKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
      "kms:CreateGrant"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "primary" {
  count = var.enable_aws_backup ? 1 : 0

  description             = "KMS CMK for primary-region AWS Backup vault encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.backup_kms.json
}

resource "aws_kms_alias" "primary" {
  count = var.enable_aws_backup ? 1 : 0

  name          = "alias/${local.prefix}-backup"
  target_key_id = aws_kms_key.primary[0].key_id
}

resource "aws_kms_key" "dr" {
  provider = aws.dr
  count    = var.enable_aws_backup && var.backup_cross_region_copy_enabled && (var.backup_dr_kms_key_arn == null || trimspace(var.backup_dr_kms_key_arn) == "") ? 1 : 0

  description             = "KMS CMK for DR-region AWS Backup vault encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.backup_kms.json
}

resource "aws_kms_alias" "dr" {
  provider = aws.dr
  count    = var.enable_aws_backup && var.backup_cross_region_copy_enabled && (var.backup_dr_kms_key_arn == null || trimspace(var.backup_dr_kms_key_arn) == "") ? 1 : 0

  name          = "alias/${local.prefix}-backup-dr"
  target_key_id = aws_kms_key.dr[0].key_id
}

resource "aws_iam_role" "backup" {
  count = var.enable_aws_backup ? 1 : 0

  name               = "${local.prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
}

resource "aws_iam_role_policy_attachment" "backup_service" {
  count = var.enable_aws_backup ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  count = var.enable_aws_backup ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_vault" "primary" {
  count = var.enable_aws_backup ? 1 : 0

  name        = local.backup_vault_name_final
  kms_key_arn = local.backup_vault_kms_key_arn
}

resource "aws_backup_vault" "dr" {
  provider = aws.dr
  count    = var.enable_aws_backup && var.backup_cross_region_copy_enabled ? 1 : 0

  name        = "${local.backup_vault_name_final}-dr-${data.aws_region.dr.region}"
  kms_key_arn = var.backup_dr_kms_key_arn != null && trimspace(var.backup_dr_kms_key_arn) != "" ? trimspace(var.backup_dr_kms_key_arn) : local.backup_dr_kms_key_arn
}

resource "aws_backup_plan" "this" {
  count = var.enable_aws_backup ? 1 : 0

  name = "${local.prefix}-rds-backup-plan"

  rule {
    rule_name         = "${local.prefix}-rds-daily"
    target_vault_name = aws_backup_vault.primary[0].name
    schedule          = var.backup_schedule_expression
    start_window      = var.backup_start_window_minutes
    completion_window = var.backup_completion_window_minutes

    lifecycle {
      delete_after = var.backup_retention_days
    }

    dynamic "copy_action" {
      for_each = var.backup_cross_region_copy_enabled ? [1] : []
      content {
        destination_vault_arn = aws_backup_vault.dr[0].arn

        lifecycle {
          delete_after = var.backup_copy_retention_days
        }
      }
    }
  }
}

resource "aws_backup_selection" "this" {
  count = var.enable_aws_backup && var.enable_backup_selection ? 1 : 0

  iam_role_arn = aws_iam_role.backup[0].arn
  name         = "${local.prefix}-backup-selection"
  plan_id      = aws_backup_plan.this[0].id
  resources    = var.backup_resource_arns

  depends_on = [
    aws_iam_role_policy_attachment.backup_service,
    aws_iam_role_policy_attachment.backup_restore,
    aws_backup_vault.primary
  ]
}
