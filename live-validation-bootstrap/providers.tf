provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Environment = "Stage"
      Service     = "live-validation-bootstrap"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Environment = "Stage"
      Service     = "live-validation-bootstrap"
    }
  }
}
