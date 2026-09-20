# =============================================================================
# budget.tf
# Monthly cost alert via AWS Budgets.
#
# ALERT STRATEGY — two complementary thresholds:
#   - FORECASTED at 100%: fires when projected month-end spend is expected to
#     exceed the limit; allows corrective action before the charge is incurred.
#   - ACTUAL at 80%: fires on real accumulated spend; acts as a safety net if
#     the forecast underestimates consumption.
#
# NOTE: The first two budgets per AWS account are free. Subsequent budgets
# cost $0.02/day each.
# =============================================================================

resource "aws_budgets_budget" "monthly_cost_alert" {
  name         = "portfolio-monthly-budget-alert"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.email_for_budgets]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.email_for_budgets]
  }
}
