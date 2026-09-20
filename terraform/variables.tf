# =============================================================================
# variables.tf
# Centralises all configurable parameters to avoid magic strings and enable
# environment/domain reuse without modifying resource definitions.
# =============================================================================

variable "aws_region" {
  description = "Primary AWS region. Most resources (S3, Lambda, DynamoDB, API GW) are provisioned here."
  type        = string
  default     = "eu-west-1"
}

variable "domain_name" {
  description = "Custom domain managed in Cloudflare (without 'www' or 'https://')."
  type        = string
  default     = "marcoaavila.dev"
}

variable "github_repo_name" {
  description = "GitHub repository allowed to deploy via OIDC. Format: 'owner/repo'."
  type        = string
  default     = "MarcoAAvila/portfolio-web"
}

variable "email_for_budgets" {
  description = "Email address for AWS Budgets alert notifications."
  type        = string
  # No default: intentionally required to avoid hardcoding personal data in source control.
  # Provide via: terraform apply -var="email_for_budgets=you@example.com"
  # or a local terraform.tfvars (already listed in .gitignore).
}

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name for the static website assets."
  type        = string
  default     = "marcoaavila-portfolio-web"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for the visitor counter."
  type        = string
  default     = "portfolio-visitor-counter"
}

variable "monthly_budget_usd" {
  description = "Monthly spend limit in USD. An alert is triggered when the forecasted cost exceeds this threshold."
  type        = number
  default     = 1.0
}
