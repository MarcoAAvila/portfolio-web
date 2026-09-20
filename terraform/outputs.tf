# =============================================================================
# outputs.tf
# Values printed after terraform apply. These are the integration points
# between Terraform and the rest of the system (Cloudflare DNS, GitHub Actions).
# =============================================================================

output "cloudfront_url" {
  description = "CloudFront domain name. Create a CNAME record in Cloudflare: '@ → this value'."
  value       = aws_cloudfront_distribution.portfolio.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID. Used in GitHub Actions to issue cache invalidations after each deploy."
  value       = aws_cloudfront_distribution.portfolio.id
}

output "acm_validation_records" {
  description = "DNS CNAME records to add in Cloudflare to complete ACM domain validation (proxy must be disabled)."
  value = {
    for dvo in aws_acm_certificate.portfolio.domain_validation_options : dvo.domain_name => {
      type  = dvo.resource_record_type
      name  = dvo.resource_record_name
      value = dvo.resource_record_value
    }
  }
}

output "api_gateway_url" {
  description = "API Gateway base URL. The frontend calls GET <this_url>/visits."
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/visits"
}

output "s3_bucket_name" {
  description = "S3 bucket name. Used in GitHub Actions: aws s3 sync ./web/ s3://<this_value>."
  value       = aws_s3_bucket.portfolio_web.bucket
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions. Store as the AWS_ROLE_ARN secret in the repository settings."
  value       = aws_iam_role.github_actions_deploy.arn
}

output "deployment_summary" {
  description = "Quick-reference summary of the deployed infrastructure."
  value       = <<-EOT

    ════════════════════════════════════════════════════════════
    ✅  INFRASTRUCTURE DEPLOYED — portfolio-web
    ════════════════════════════════════════════════════════════

    🌐 DOMAIN:
       ${var.domain_name} → CNAME → ${aws_cloudfront_distribution.portfolio.domain_name}

    📦 S3 BUCKET:
       ${aws_s3_bucket.portfolio_web.bucket}

    🚀 API ENDPOINT (visitor counter):
       GET ${aws_apigatewayv2_stage.default.invoke_url}/visits

    🔐 GitHub Actions Role ARN:
       ${aws_iam_role.github_actions_deploy.arn}
  EOT
}
