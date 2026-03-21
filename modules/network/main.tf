resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

data "aws_region" "current" {}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

locals {
  nat_gateway_count = var.private_app_nat_mode == "required" ? length(var.availability_zones) : (
    var.private_app_nat_mode == "canary" && length(var.availability_zones) > 0 ? 1 : 0
  )
  flow_logs_name_prefix = (
    var.flow_logs_name_prefix != null && trimspace(var.flow_logs_name_prefix) != ""
  ) ? trimspace(var.flow_logs_name_prefix) : var.vpc_name

  private_app_nat_routes = var.private_app_nat_mode == "required" ? {
    for idx in range(length(var.availability_zones)) : tostring(idx) => idx
    } : (
    var.private_app_nat_mode == "canary" && length(var.availability_zones) > 0 ? {
      "0" = 0
    } : {}
  )
}

resource "aws_default_security_group" "lockdown" {
  count = var.lockdown_default_security_group ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-default-sg-lockdown"
  }
}

data "aws_iam_policy_document" "vpc_flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name               = "${local.flow_logs_name_prefix}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume_role.json
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${local.flow_logs_name_prefix}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.flow_logs_kms_key_id
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${local.flow_logs_name_prefix}-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  #tfsec:ignore:aws-iam-no-policy-wildcards CloudWatch Logs stream ARNs require wildcard suffixes and cannot be enumerated ahead of time.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams"
        ]
        Resource = aws_cloudwatch_log_group.vpc_flow_logs.arn
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  iam_role_arn             = aws_iam_role.vpc_flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type             = "ALL"
  max_aggregation_interval = 60
  vpc_id                   = aws_vpc.this.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "public_edge" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-public-edge-${count.index + 1}"
    Tier = "public-edge"
  }
}

resource "aws_subnet" "private_app" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-private-app-${count.index + 1}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_db" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-private-db-${count.index + 1}"
    Tier = "private-db"
  }
}

resource "aws_security_group" "interface_endpoints" {
  #checkov:skip=CKV2_AWS_5: Attached directly to Interface VPC Endpoints created in this module.
  name        = "${var.vpc_name}-vpce-sg"
  description = "Allow HTTPS to Interface VPC Endpoints from private app subnets"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from private app subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_app_subnet_cidrs
  }

  egress = []
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoint_services)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [aws_security_group.interface_endpoints.id]
  private_dns_enabled = true
}

resource "aws_route_table" "public_edge" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.vpc_name}-public-edge-rt"
  }
}

resource "aws_route_table_association" "public_edge" {
  count = length(aws_subnet.public_edge)

  subnet_id      = aws_subnet.public_edge[count.index].id
  route_table_id = aws_route_table.public_edge.id
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_edge[count.index].id

  tags = {
    Name = "${var.vpc_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_app" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-private-app-rt-${count.index + 1}"
  }
}

resource "aws_route" "private_app_default" {
  for_each = local.private_app_nat_routes

  route_table_id         = aws_route_table.private_app[tonumber(each.key)].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value].id
}

resource "aws_route_table_association" "private_app" {
  count = length(aws_subnet.private_app)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-private-db-rt"
  }
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    aws_route_table.private_app[*].id,
    [aws_route_table.private_db.id]
  )
}

resource "aws_route_table_association" "private_db" {
  count = length(aws_subnet.private_db)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
