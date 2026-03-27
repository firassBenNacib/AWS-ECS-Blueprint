mock_provider "aws" {}

variables {
  name_prefix                  = "platform"
  enable_budget_alerts         = true
  notification_email_addresses = ["ops@example.com"]
  total_monthly_limit          = 300
  cloudfront_monthly_limit     = 75
  vpc_monthly_limit            = 50
  rds_monthly_limit            = 125
}

run "all_budget_categories_can_be_created" {
  command = plan

  assert {
    condition     = length(aws_budgets_budget.this) == 4
    error_message = "All configured budget categories should be created."
  }

  assert {
    condition     = aws_budgets_budget.this["total"].name == "platform-total-monthly-cost"
    error_message = "The total budget should use the expected derived name."
  }

  assert {
    condition     = contains(flatten([for filter in aws_budgets_budget.this["cloudfront"].cost_filter : filter.values]), "Amazon CloudFront")
    error_message = "The CloudFront budget should scope to the CloudFront service."
  }
}

run "disabled_budget_alerts_create_nothing" {
  command = plan

  variables {
    enable_budget_alerts = false
  }

  assert {
    condition     = length(aws_budgets_budget.this) == 0
    error_message = "Budgets should not be created when disabled."
  }
}

run "missing_subscribers_is_rejected" {
  command = plan

  variables {
    notification_email_addresses = []
  }

  expect_failures = [
    aws_budgets_budget.this
  ]
}
