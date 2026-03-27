locals {
  budget_alerts_enabled = var.enable_budget_alerts

  budget_definitions = {
    total = {
      limit_amount  = var.total_monthly_limit
      filter_name   = null
      filter_values = []
    }
    cloudfront = {
      limit_amount  = var.cloudfront_monthly_limit
      filter_name   = "Service"
      filter_values = ["Amazon CloudFront"]
    }
    vpc = {
      limit_amount  = var.vpc_monthly_limit
      filter_name   = "Service"
      filter_values = ["Amazon Virtual Private Cloud"]
    }
    rds = {
      limit_amount  = var.rds_monthly_limit
      filter_name   = "Service"
      filter_values = ["Amazon Relational Database Service"]
    }
  }

  active_budget_definitions = {
    for key, cfg in local.budget_definitions :
    key => cfg
    if local.budget_alerts_enabled && cfg.limit_amount != null
  }
}

resource "aws_budgets_budget" "this" {
  for_each = local.active_budget_definitions

  name         = "${var.name_prefix}-${replace(each.key, "_", "-")}-monthly-cost"
  budget_type  = "COST"
  limit_amount = tostring(each.value.limit_amount)
  limit_unit   = var.limit_unit
  time_unit    = "MONTHLY"

  dynamic "cost_filter" {
    for_each = each.value.filter_name != null ? [each.value] : []

    content {
      name   = cost_filter.value.filter_name
      values = cost_filter.value.filter_values
    }
  }

  dynamic "notification" {
    for_each = toset(var.alert_threshold_percentages)

    content {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "ACTUAL"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = var.notification_email_addresses
      subscriber_sns_topic_arns  = var.notification_topic_arns
    }
  }

  lifecycle {
    precondition {
      condition     = !local.budget_alerts_enabled || length(var.notification_email_addresses) + length(var.notification_topic_arns) > 0
      error_message = "At least one email address or SNS topic ARN must be provided when budget alerts are enabled."
    }
  }
}
