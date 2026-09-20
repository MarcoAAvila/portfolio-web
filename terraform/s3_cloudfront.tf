# =============================================================================
# s3_cloudfront.tf
# Static website hosting infrastructure.
#
# ARCHITECTURE:
#   Internet → CloudFront → OAC → S3 (private)
#
# WHY NOT S3 STATIC WEBSITE HOSTING:
#   Enabling S3 static hosting makes the bucket publicly accessible over HTTP.
#   With OAC (Origin Access Control), the bucket remains fully private; only
#   CloudFront can read objects via a scoped IAM bucket policy.
#   OAC replaced the legacy OAI (Origin Access Identity) pattern in 2022.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. S3 Bucket — private store for static assets
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "portfolio_web" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "portfolio-web-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# 2. Origin Access Control (OAC)
# CloudFront signs every request to S3 with SigV4, allowing the bucket policy
# to restrict access to this specific distribution's service principal.
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "portfolio_oac" {
  name                              = "portfolio-oac"
  description                       = "OAC for secure CloudFront-to-S3 access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# 3. S3 Bucket Policy
# Grants GetObject only to requests originating from this specific CloudFront
# distribution. Any other distribution pointing at this bucket will be denied.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.portfolio_web.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.portfolio.arn
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# 4. CloudFront Distribution
# CDN layer providing HTTPS termination, global edge caching, and the ACM
# certificate from us-east-1 (required by CloudFront regardless of origin region).
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Portfolio web distribution - ${var.domain_name}"
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]

  origin {
    domain_name              = aws_s3_bucket.portfolio_web.bucket_regional_domain_name
    origin_id                = "S3-${var.s3_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.s3_bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # AWS managed policy "CachingOptimized" — TTL range 1s–1yr; ideal for versioned static assets.
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # S3 returns 403 (not 404) for missing objects when the bucket is private.
  # This mapping surfaces a proper 404 to the client and serves a custom error page.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  # PriceClass_100 limits edge locations to North America + Europe,
  # reducing cost vs. the global price class with negligible latency impact
  # for the expected audience.
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.portfolio.certificate_arn
    # sni-only avoids the $600/month dedicated IP option; supported by all modern browsers.
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "portfolio-cloudfront"
  }
}
