provider "aws" {
  region = var.aws_region

  dynamic "assume_role" {
    for_each = local.nonprod_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.nonprod_role_arn_effective
      session_name = "terraform-nonprod-app"
      external_id  = var.assume_role_external_id
    }
  }

  default_tags {
    tags = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = "nonprod"
      },
      local.contract_tags
    )
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  dynamic "assume_role" {
    for_each = local.nonprod_us_east_1_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.nonprod_us_east_1_role_arn_effective
      session_name = "terraform-nonprod-app"
      external_id  = var.assume_role_external_id
    }
  }

  default_tags {
    tags = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = "nonprod"
      },
      local.contract_tags
    )
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  dynamic "assume_role" {
    for_each = local.nonprod_dr_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.nonprod_dr_role_arn_effective
      session_name = "terraform-nonprod-app"
      external_id  = var.assume_role_external_id
    }
  }

  default_tags {
    tags = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = "nonprod"
      },
      local.contract_tags
    )
  }
}
