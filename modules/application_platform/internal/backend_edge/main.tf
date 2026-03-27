module "alb" {
  source = "../../../alb"

  vpc_id                            = var.ingress.selected_vpc_id
  alb_subnet_ids                    = var.ingress.selected_alb_subnet_ids
  internal                          = var.ingress.backend_ingress_is_vpc_origin
  alb_security_group_id             = var.ingress.alb_security_group_id
  app_port                          = var.ingress.alb_app_port
  alb_listener_port                 = var.ingress.alb_listener_port
  certificate_arn                   = var.alb_config.certificate_arn
  ssl_policy                        = var.alb_config.ssl_policy
  health_check_path                 = var.ingress.alb_health_check_path
  health_check_matcher              = var.alb_config.health_check_matcher
  health_check_interval_seconds     = var.alb_config.health_check_interval_seconds
  health_check_timeout_seconds      = var.alb_config.health_check_timeout_seconds
  health_check_healthy_threshold    = var.alb_config.health_check_healthy_threshold
  health_check_unhealthy_threshold  = var.alb_config.health_check_unhealthy_threshold
  target_type                       = "ip"
  alb_name                          = var.alb_config.alb_name
  target_group_name                 = var.alb_config.target_group_name
  enable_environment_suffix         = var.environment.enable_suffix
  environment_name_override         = var.environment.name
  enable_deletion_protection        = var.alb_config.deletion_protection
  idle_timeout                      = var.alb_config.idle_timeout
  access_logs_bucket                = var.alb_config.access_logs_bucket
  access_logs_prefix                = var.alb_config.access_logs_prefix
  enable_origin_auth_header         = var.ingress.origin_auth_enabled
  origin_auth_header_name           = var.ingress.origin_auth_header_name
  origin_auth_header_value          = var.ingress.origin_auth_header_value
  origin_auth_previous_header_name  = var.ingress.origin_auth_previous_header_name
  origin_auth_previous_header_value = var.ingress.origin_auth_previous_header_value
}

resource "aws_cloudfront_vpc_origin" "backend_primary" {
  count = var.ingress.backend_ingress_is_vpc_origin ? 1 : 0

  vpc_origin_endpoint_config {
    arn                    = module.alb.alb_arn
    http_port              = 80
    https_port             = var.ingress.alb_listener_port
    name                   = var.environment.enable_suffix ? "backend-origin-${var.environment.name}" : "backend-origin"
    origin_protocol_policy = "https-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

data "aws_security_group" "cloudfront_vpc_origin" {
  count      = var.ingress.runtime_mode_is_micro && var.ingress.backend_ingress_is_vpc_origin ? 1 : 0
  depends_on = [aws_cloudfront_vpc_origin.backend_primary]

  filter {
    name   = "group-name"
    values = ["CloudFront-VPCOrigins-Service-SG"]
  }

  filter {
    name   = "vpc-id"
    values = [var.ingress.selected_vpc_id]
  }
}

resource "aws_security_group_rule" "microservices_cloudfront_to_alb_https" {
  count = var.ingress.runtime_mode_is_micro && var.ingress.backend_ingress_is_vpc_origin ? 1 : 0

  type                     = "ingress"
  from_port                = var.ingress.alb_listener_port
  to_port                  = var.ingress.alb_listener_port
  protocol                 = "tcp"
  security_group_id        = var.ingress.microservices_alb_security_group_id
  source_security_group_id = data.aws_security_group.cloudfront_vpc_origin[0].id
  description              = "Allow CloudFront VPC origin traffic to the ALB HTTPS listener."
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  count = var.ingress.runtime_mode_is_micro && var.ingress.backend_ingress_is_public ? 1 : 0

  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group_rule" "microservices_cloudfront_prefix_to_alb_https" {
  count = var.ingress.runtime_mode_is_micro && var.ingress.backend_ingress_is_public ? 1 : 0

  type              = "ingress"
  from_port         = var.ingress.alb_listener_port
  to_port           = var.ingress.alb_listener_port
  protocol          = "tcp"
  security_group_id = var.ingress.microservices_alb_security_group_id
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing[0].id]
  description       = "Allow CloudFront origin-facing prefix list traffic to the public-restricted ALB HTTPS listener."
}

resource "aws_wafv2_web_acl" "alb" {
  count = var.waf_config.create_managed_alb ? 1 : 0

  name  = var.environment.enable_suffix ? "backend-alb-waf-${var.environment.name}" : "backend-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.environment.enable_suffix ? "backend-alb-waf-${var.environment.name}" : "backend-alb-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.environment.enable_suffix ? "alb-known-bad-inputs-${var.environment.name}" : "alb-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.environment.enable_suffix ? "alb-common-rules-${var.environment.name}" : "alb-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_config.rate_limit_requests
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.environment.enable_suffix ? "alb-rate-limit-${var.environment.name}" : "alb-rate-limit"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_cloudwatch_log_group" "waf_alb" {
  count = var.waf_config.create_managed_alb ? 1 : 0

  name              = var.environment.enable_suffix ? "aws-waf-logs-backend-alb-${var.environment.name}" : "aws-waf-logs-backend-alb"
  retention_in_days = var.waf_config.log_retention_days
  kms_key_id        = null
}

resource "aws_wafv2_web_acl_logging_configuration" "alb" {
  count = var.waf_config.create_managed_alb ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf_alb[0].arn]
  resource_arn            = aws_wafv2_web_acl.alb[0].arn
}

resource "aws_wafv2_web_acl_association" "alb_managed" {
  count = var.waf_config.create_managed_alb ? 1 : 0

  resource_arn = module.alb.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb[0].arn
}

resource "aws_wafv2_web_acl_association" "alb_custom" {
  count = var.waf_config.alb_web_acl_arn != null ? 1 : 0

  resource_arn = module.alb.alb_arn
  web_acl_arn  = var.waf_config.alb_web_acl_arn
}

resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1
  count    = var.waf_config.create_managed_cloudfront ? 1 : 0

  name  = var.environment.enable_suffix ? "cloudfront-waf-${var.environment.name}" : "cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.environment.enable_suffix ? "cloudfront-waf-${var.environment.name}" : "cloudfront-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.environment.enable_suffix ? "cf-known-bad-inputs-${var.environment.name}" : "cf-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.environment.enable_suffix ? "cf-common-rules-${var.environment.name}" : "cf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_config.rate_limit_requests
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.environment.enable_suffix ? "cf-rate-limit-${var.environment.name}" : "cf-rate-limit"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_cloudwatch_log_group" "waf_cloudfront" {
  provider = aws.us_east_1
  count    = var.waf_config.create_managed_cloudfront ? 1 : 0

  name              = var.environment.enable_suffix ? "aws-waf-logs-cloudfront-${var.environment.name}" : "aws-waf-logs-cloudfront"
  retention_in_days = var.waf_config.log_retention_days
  kms_key_id        = null
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  provider = aws.us_east_1
  count    = var.waf_config.create_managed_cloudfront ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf_cloudfront[0].arn]
  resource_arn            = aws_wafv2_web_acl.cloudfront[0].arn
}
