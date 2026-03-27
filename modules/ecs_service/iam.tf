data "aws_iam_policy_document" "execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = var.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role.json
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  count = length(var.secret_arns) > 0 || length(var.secret_kms_key_arns) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []
    content {
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      resources = local.secret_policy_resources
    }
  }

  dynamic "statement" {
    for_each = length(var.secret_kms_key_arns) > 0 ? [1] : []
    content {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = var.secret_kms_key_arns
    }
  }
}

resource "aws_iam_policy" "execution_secrets" {
  count = length(var.secret_arns) > 0 || length(var.secret_kms_key_arns) > 0 ? 1 : 0

  name   = "${var.execution_role_name}-secrets"
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

resource "aws_iam_role_policy_attachment" "execution_secrets" {
  count = length(var.secret_arns) > 0 || length(var.secret_kms_key_arns) > 0 ? 1 : 0

  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution_secrets[0].arn
}

resource "aws_iam_role" "task" {
  name               = var.task_role_name
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role.json
}

data "aws_iam_policy_document" "task_exec_kms" {
  count = var.enable_execute_command && var.exec_kms_key_arn != null ? 1 : 0

  statement {
    actions   = ["kms:Decrypt"]
    resources = [var.exec_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "task_exec_kms" {
  count = var.enable_execute_command && var.exec_kms_key_arn != null ? 1 : 0

  name   = "${var.task_role_name}-exec-kms"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_exec_kms[0].json
}

resource "aws_iam_role_policy" "task_inline" {
  count = var.task_role_policy_json == null ? 0 : 1

  name   = "${var.task_role_name}-inline"
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}
