# =============================================================================
# iam_oidc.tf
# Configures keyless authentication between GitHub Actions and AWS via OIDC.
#
# OIDC FLOW:
#   1. AWS trusts GitHub as an identity provider.
#   2. When a GitHub Actions job runs, GitHub issues a short-lived, signed JWT
#      that asserts: "I am repo X, on branch Y".
#   3. The workflow exchanges that JWT for temporary AWS credentials via
#      sts:AssumeRoleWithWebIdentity.
#   4. AWS verifies the JWT signature against GitHub's JWKS endpoint and,
#      if the trust conditions match, returns credentials valid for 1 hour.
#
#   Result: zero long-lived secrets stored anywhere.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# 1. OIDC Provider — registers GitHub as a trusted identity source in AWS
# =============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # Official thumbprints for GitHub's token endpoint TLS certificate.
  # AWS validates JWT signatures automatically since 2023, but the field
  # remains mandatory in the Terraform resource schema.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# =============================================================================
# 2. Trust policy — who can assume this role
# =============================================================================

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:MarcoAAvila/portfolio-web:ref:refs/heads/main"]
    }
  }
}

# =============================================================================
# 3. IAM Role — assumed by GitHub Actions during the deployment job
# =============================================================================

resource "aws_iam_role" "github_actions_deploy" {
  name               = "portfolio-github-actions-deploy"
  description        = "Deployment role for GitHub Actions - assumed via OIDC"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  # 1 hour is sufficient for a typical deployment pipeline.
  max_session_duration = 3600

  tags = {
    Name = "portfolio-github-actions-role"
  }
}

# =============================================================================
# 4. Permissions — least-privilege policy for the deployment workflow
# =============================================================================

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "S3DeployWebsite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.portfolio_web.arn,
      "${aws_s3_bucket.portfolio_web.arn}/*",
    ]
  }

  statement {
    sid    = "CloudFrontInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
    ]
    resources = [aws_cloudfront_distribution.portfolio.arn]
  }

  statement {
    sid    = "LambdaDeploy"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction",
    ]
    resources = [aws_lambda_function.visitor_counter.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_permissions" {
  name   = "portfolio-github-actions-permissions"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
