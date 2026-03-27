data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id
}

resource "aws_cloudwatch_log_group" "exec" {
  count = var.enable_execute_command && var.exec_log_group_name != null ? 1 : 0

  name              = var.exec_log_group_name
  retention_in_days = var.exec_log_retention_days
  kms_key_id        = var.exec_kms_key_arn
}
