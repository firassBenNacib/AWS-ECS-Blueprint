provider "aws" {
  region = var.aws_region

  dynamic "assume_role" {
    for_each = local.prod_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.prod_role_arn_effective
      session_name = "terraform-prod-app"
      external_id  = var.assume_role_external_id
    }
  }

  default_tags {
    tags = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = "Prod"
        Service     = var.project_name
      },
      local.contract_tags
    )
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  dynamic "assume_role" {
    for_each = local.prod_us_east_1_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.prod_us_east_1_role_arn_effective
      session_name = "terraform-prod-app"
      external_id  = var.assume_role_external_id
    }
  }

  default_tags {
    tags = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = "Prod"
        Service     = var.project_name
      },
      local.contract_tags
    )
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  dynamic "assume_role" {
    for_each = local.prod_dr_role_arn_effective != null ? [1] : []
    content {
      role_arn     = local.prod_dr_role_arn_effective
      session_name = "terraform-prod-app"
      external_id  = var.assume_role_external_id
    }
  }

  default_tags {
    tags = merge(
      {
        ManagedBy   = "Terraform"
        Project     = var.project_name
        Environment = "Prod"
        Service     = var.project_name
      },
      local.contract_tags
    )
  }
}
