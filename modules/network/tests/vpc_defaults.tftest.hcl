mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  vpc_cidr                 = "10.0.0.0/16"
  availability_zones       = ["eu-west-1a", "eu-west-1b"]
  public_app_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
  private_db_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
}

run "dns_support_enabled" {
  command = plan

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "VPC should have DNS support enabled."
  }
}

run "dns_hostnames_enabled" {
  command = plan

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "VPC should have DNS hostnames enabled."
  }
}

run "public_subnets_no_auto_public_ip" {
  command = plan

  assert {
    condition     = aws_subnet.public_edge[0].map_public_ip_on_launch == false
    error_message = "Public edge subnets should not auto-assign public IPs."
  }
}

run "private_app_subnets_no_public_ip" {
  command = plan

  assert {
    condition     = aws_subnet.private_app[0].map_public_ip_on_launch == false
    error_message = "Private app subnets should not auto-assign public IPs."
  }
}

run "private_db_subnets_no_public_ip" {
  command = plan

  assert {
    condition     = aws_subnet.private_db[0].map_public_ip_on_launch == false
    error_message = "Private DB subnets should not auto-assign public IPs."
  }
}

run "default_sg_lockdown_enabled" {
  command = plan

  assert {
    condition     = length(aws_default_security_group.lockdown) == 1
    error_message = "Default security group lockdown should be created by default."
  }
}

run "flow_logs_created" {
  command = plan

  assert {
    condition     = aws_flow_log.vpc.traffic_type == "ALL"
    error_message = "VPC flow logs should capture ALL traffic."
  }

  assert {
    condition     = aws_flow_log.vpc.max_aggregation_interval == 60
    error_message = "VPC flow logs should use 60-second aggregation."
  }
}

run "nat_per_az_in_required_mode" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "Required NAT mode should create one NAT gateway per AZ."
  }

  assert {
    condition     = length(aws_eip.nat) == 2
    error_message = "Required NAT mode should create one EIP per NAT gateway."
  }
}

run "single_nat_in_canary_mode" {
  command = plan

  variables {
    private_app_nat_mode = "canary"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Canary NAT mode should create exactly one NAT gateway."
  }
}

run "no_nat_in_disabled_mode" {
  command = plan

  variables {
    private_app_nat_mode = "disabled"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0
    error_message = "Disabled NAT mode should not create any NAT gateways."
  }

  assert {
    condition     = length(aws_eip.nat) == 0
    error_message = "Disabled NAT mode should not create any EIPs."
  }
}

run "s3_gateway_endpoint_created" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.s3_gateway.vpc_endpoint_type == "Gateway"
    error_message = "S3 VPC endpoint should be a Gateway type."
  }
}

run "igw_has_lifecycle_create_before_destroy" {
  command = plan

  assert {
    condition     = aws_internet_gateway.this.tags.Name == "app-vpc-igw"
    error_message = "Internet gateway should use the expected name tag."
  }
}
