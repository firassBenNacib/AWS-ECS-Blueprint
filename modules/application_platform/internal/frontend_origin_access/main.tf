data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  count = var.frontend.runtime_is_s3 ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      var.frontend.frontend_primary_bucket_arn,
      "${var.frontend.frontend_primary_bucket_arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.frontend.frontend_primary_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.frontend.distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  count  = var.frontend.runtime_is_s3 ? 1 : 0
  bucket = var.frontend.frontend_primary_bucket_name
  policy = data.aws_iam_policy_document.frontend_bucket_policy[0].json
}

data "aws_iam_policy_document" "frontend_dr_bucket_policy" {
  count = var.frontend.runtime_is_s3 ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      var.frontend.frontend_dr_bucket_arn,
      "${var.frontend.frontend_dr_bucket_arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowCloudFrontReadObjects"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.frontend.frontend_dr_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.frontend.distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_dr_policy" {
  count    = var.frontend.runtime_is_s3 ? 1 : 0
  provider = aws.dr

  bucket = var.frontend.frontend_dr_bucket_name
  policy = data.aws_iam_policy_document.frontend_dr_bucket_policy[0].json
}
