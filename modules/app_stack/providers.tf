locals {
  primary_assume_role_arn_effective = (
    var.aws_assume_role_arn != null && trimspace(var.aws_assume_role_arn) != ""
  ) ? trimspace(var.aws_assume_role_arn) : null

  us_east_1_assume_role_arn_effective = (
    var.us_east_1_assume_role_arn != null && trimspace(var.us_east_1_assume_role_arn) != ""
  ) ? trimspace(var.us_east_1_assume_role_arn) : local.primary_assume_role_arn_effective

  dr_assume_role_arn_effective = (
    var.dr_assume_role_arn != null && trimspace(var.dr_assume_role_arn) != ""
  ) ? trimspace(var.dr_assume_role_arn) : local.primary_assume_role_arn_effective
}

provider "aws" {
  region = var.aws_region

  dynamic "assume_role" {
    for_each = local.primary_assume_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.primary_assume_role_arn_effective
      session_name = var.aws_assume_role_session_name
      external_id  = var.aws_assume_role_external_id
    }
  }

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  dynamic "assume_role" {
    for_each = local.us_east_1_assume_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.us_east_1_assume_role_arn_effective
      session_name = var.aws_assume_role_session_name
      external_id  = var.aws_assume_role_external_id
    }
  }

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  dynamic "assume_role" {
    for_each = local.dr_assume_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.dr_assume_role_arn_effective
      session_name = var.aws_assume_role_session_name
      external_id  = var.aws_assume_role_external_id
    }
  }

  default_tags {
    tags = local.common_tags
  }
}
