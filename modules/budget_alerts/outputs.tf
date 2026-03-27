output "budget_names" {
  description = "Budget names keyed by logical budget category."
  value       = { for key, budget in aws_budgets_budget.this : key => budget.name }
}

output "budget_arns" {
  description = "Budget ARNs keyed by logical budget category."
  value       = { for key, budget in aws_budgets_budget.this : key => budget.arn }
}
