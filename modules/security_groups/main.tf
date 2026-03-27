data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

locals {
  environment_name = (
    var.environment_name_override != null && trimspace(var.environment_name_override) != ""
  ) ? trimspace(var.environment_name_override) : terraform.workspace
  suffix = var.enable_environment_suffix ? "-${local.environment_name}" : ""
}

moved {
  from = aws_security_group.backend_ec2
  to   = aws_security_group.backend_service
}

moved {
  from = aws_security_group_rule.backend_alb_to_backend_ec2
  to   = aws_security_group_rule.backend_alb_to_backend_service
}

resource "aws_security_group" "backend_alb" {
  #checkov:skip=CKV2_AWS_5: Attached via module output to the ALB in the root module.
  name        = "backend-alb-sg${local.suffix}"
  description = "Allow backend ALB traffic from VPC-internal CloudFront VPC origin path"
  vpc_id      = var.vpc_id

  ingress {
    description     = "ALB listener from CloudFront origin-facing infrastructure"
    from_port       = var.alb_listener_port
    to_port         = var.alb_listener_port
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront_origin.id]
  }
}

resource "aws_security_group" "backend_service" {
  #checkov:skip=CKV2_AWS_5: Attached via module output to backend ECS tasks in the root module.
  name        = "backend-service-sg${local.suffix}"
  description = "Allow backend service traffic only from ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Backend app port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb.id]
  }

  dynamic "egress" {
    for_each = var.egress_endpoint_sg_id == null ? [] : [var.egress_endpoint_sg_id]
    content {
      description     = "Allow HTTPS egress to Interface VPC Endpoints"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [egress.value]
    }
  }

  dynamic "egress" {
    for_each = var.egress_s3_prefix_list_id == null ? [] : [var.egress_s3_prefix_list_id]
    content {
      description     = "Allow HTTPS egress to Amazon S3 via the gateway endpoint"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      prefix_list_ids = [egress.value]
    }
  }

  egress {
    description = "Allow DNS over UDP to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    description = "Allow DNS over TCP to VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
}

resource "aws_security_group_rule" "backend_alb_to_backend_service" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_alb.id
  source_security_group_id = aws_security_group.backend_service.id
  description              = "Forward backend traffic from ALB to backend service only"
}

resource "aws_security_group_rule" "backend_service_to_rds" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_service.id
  source_security_group_id = aws_security_group.rds.id
  description              = "Allow backend service connections to RDS only"
}

resource "aws_security_group" "rds" {
  #checkov:skip=CKV2_AWS_5: Attached via module output to the RDS instance in the root module.
  name        = "rds-from-backend-sg${local.suffix}"
  description = "Allow database access only from backend service security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from backend service"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_service.id]
  }

  egress {
    description = "Restrict outbound traffic to VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
}
