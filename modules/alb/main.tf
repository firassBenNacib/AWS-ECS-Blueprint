locals {
  environment_name = (
    var.environment_name_override != null && trimspace(var.environment_name_override) != ""
  ) ? trimspace(var.environment_name_override) : terraform.workspace
  suffix = var.enable_environment_suffix ? "-${local.environment_name}" : ""

  alb_name_final          = "${var.alb_name}${local.suffix}"
  target_group_name_final = "${var.target_group_name}${local.suffix}"
}

resource "aws_lb" "this" {
  name               = local.alb_name_final
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.alb_subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = true
  }
}

resource "aws_lb_target_group" "backend" {
  #checkov:skip=CKV_AWS_378: TLS is terminated at CloudFront/ALB; backend target traffic remains private and HTTP-only inside VPC.
  name        = local.target_group_name_final
  port        = var.app_port
  protocol    = "HTTP"
  target_type = var.target_type
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval_seconds
    timeout             = var.health_check_timeout_seconds
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_listener_port
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  dynamic "default_action" {
    for_each = var.enable_origin_auth_header ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.backend.arn
    }
  }

  dynamic "default_action" {
    for_each = var.enable_origin_auth_header ? [1] : []
    content {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "Forbidden"
        status_code  = "403"
      }
    }
  }
}

resource "aws_lb_listener_rule" "origin_auth_primary" {
  count = var.enable_origin_auth_header && trimspace(var.origin_auth_header_value) != "" ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    http_header {
      http_header_name = var.origin_auth_header_name
      values           = [var.origin_auth_header_value]
    }
  }
}

resource "aws_lb_listener_rule" "origin_auth_secondary" {
  count = var.enable_origin_auth_header && trimspace(var.origin_auth_previous_header_value) != "" ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 11

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    http_header {
      http_header_name = var.origin_auth_previous_header_name
      values           = [var.origin_auth_previous_header_value]
    }
  }
}
