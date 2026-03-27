terraform {
  required_version = ">= 1.8.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
      configuration_aliases = [
        aws.dr
      ]
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3, < 3.0"
    }
  }
}
