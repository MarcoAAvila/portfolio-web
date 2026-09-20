# =============================================================================
# acm.tf
# Requests a public TLS certificate from AWS Certificate Manager (ACM).
#
# VALIDATION FLOW:
#   1. ACM issues CNAME records proving domain ownership.
#   2. Add those CNAMEs in Cloudflare (proxy disabled — DNS only).
#   3. Once ACM validates the CNAMEs, the certificate transitions to ISSUED.
#
# REGION CONSTRAINT:
#   CloudFront only accepts ACM certificates from us-east-1, regardless of
#   where the distribution or origin resources are managed.
# =============================================================================

resource "aws_acm_certificate" "portfolio" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method = "DNS"

  lifecycle {
    # Ensures the replacement certificate is fully issued before the old one
    # is destroyed, preventing CloudFront downtime during renewals.
    create_before_destroy = true
  }

  tags = {
    Name = "portfolio-acm-cert"
  }
}

resource "aws_acm_certificate_validation" "portfolio" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.portfolio.arn

  validation_record_fqdns = [
    for dvo in aws_acm_certificate.portfolio.domain_validation_options : dvo.resource_record_name
  ]
}
