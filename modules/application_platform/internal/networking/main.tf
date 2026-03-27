module "network" {
  source = "../../../network"

  vpc_name                        = var.network.vpc_name
  vpc_cidr                        = var.network.vpc_cidr
  availability_zones              = var.network.availability_zones
  public_app_subnet_cidrs         = var.network.public_app_subnet_cidrs
  private_app_subnet_cidrs        = var.network.private_app_subnet_cidrs
  private_db_subnet_cidrs         = var.network.private_db_subnet_cidrs
  flow_logs_retention_days        = var.network.flow_logs_retention_days
  flow_logs_kms_key_id            = var.network.flow_logs_kms_key_id
  flow_logs_name_prefix           = var.network.flow_logs_name_prefix
  lockdown_default_security_group = var.network.lockdown_default_security_group
  interface_endpoint_services     = var.network.interface_endpoint_services
  private_app_nat_mode            = var.network.private_app_nat_mode
}

module "security_groups" {
  count  = var.security.runtime_mode_is_single ? 1 : 0
  source = "../../../security_groups"

  vpc_id                    = module.network.vpc_id
  app_port                  = var.security.backend_container_port
  alb_listener_port         = var.security.alb_listener_port
  egress_endpoint_sg_id     = module.network.interface_endpoints_sg_id
  egress_s3_prefix_list_id  = module.network.s3_gateway_prefix_list_id
  enable_environment_suffix = var.environment.enable_suffix
  environment_name_override = var.environment.name
}

resource "aws_security_group" "microservices_alb" {
  count = var.security.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-alb-sg-${var.environment.name}"
  description = "Allow CloudFront VPC-origin traffic to the public ECS service ALB."
  vpc_id      = module.network.vpc_id
}

resource "aws_security_group" "microservices_gateway" {
  count = var.security.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-gateway-sg-${var.environment.name}"
  description = "Allow ALB traffic to the public gateway ECS service."
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "Public service traffic from the internal ALB"
    from_port       = var.security.public_service_port
    to_port         = var.security.public_service_port
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_alb[0].id]
  }

  egress {
    description = "Allow DNS over UDP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.security.vpc_cidr]
  }

  egress {
    description = "Allow DNS over TCP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.security.vpc_cidr]
  }

  egress {
    description     = "HTTPS to VPC interface endpoints (ECR, CloudWatch, Secrets Manager, KMS)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.network.interface_endpoints_sg_id]
  }

  egress {
    description     = "HTTPS to Amazon S3 via the gateway endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [module.network.s3_gateway_prefix_list_id]
  }

  egress {
    description     = "Internal service-to-service traffic within the private subnet tier"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal[0].id]
  }
}

resource "aws_security_group_rule" "microservices_alb_to_gateway" {
  count = var.security.runtime_mode_is_micro ? 1 : 0

  type                     = "egress"
  from_port                = var.security.public_service_port
  to_port                  = var.security.public_service_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.microservices_alb[0].id
  source_security_group_id = aws_security_group.microservices_gateway[0].id
  description              = "Forward ALB traffic to the public ECS service only."
}

resource "aws_security_group" "microservices_internal" {
  count = var.security.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-internal-sg-${var.environment.name}"
  description = "Allow east-west traffic between private ECS services."
  vpc_id      = module.network.vpc_id

  ingress {
    description = "Allow internal service-to-service traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow internal service-to-service traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow DNS over UDP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.security.vpc_cidr]
  }

  egress {
    description = "Allow DNS over TCP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.security.vpc_cidr]
  }

  egress {
    description     = "HTTPS to VPC interface endpoints (ECR, CloudWatch, Secrets Manager, KMS)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.network.interface_endpoints_sg_id]
  }

  egress {
    description     = "HTTPS to Amazon S3 via the gateway endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [module.network.s3_gateway_prefix_list_id]
  }

  egress {
    description = "MySQL to RDS within the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.security.vpc_cidr]
  }
}

resource "aws_security_group" "microservices_extra_egress" {
  for_each = var.security.runtime_mode_is_micro ? {
    for service_name, service in var.security.ecs_services_final :
    service_name => service if length(coalesce(service.extra_egress, [])) > 0
  } : {}

  name        = "microservices-extra-egress-${each.key}-${var.environment.name}"
  description = "Additional egress exceptions for ${each.key}."
  vpc_id      = module.network.vpc_id

  dynamic "egress" {
    for_each = coalesce(each.value.extra_egress, [])
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_security_group" "microservices_rds" {
  count = var.security.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-rds-sg-${var.environment.name}"
  description = "Allow MySQL access from private ECS services."
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "MySQL from private ECS services"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal[0].id]
  }

  egress {
    description = "Restrict outbound traffic to the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.security.vpc_cidr]
  }
}
