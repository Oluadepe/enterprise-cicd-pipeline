provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# --- ECR repo ---
resource "aws_ecr_repository" "repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project = var.project
  }
}

# --- GitHub OIDC provider (global) ---
# You only need one of these per AWS account. If it already exists, import it instead.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub OIDC thumbprint (stable): GitHub documents and AWS examples commonly use this.
  # If your org requires strict validation, confirm thumbprint in your environment.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# --- IAM role for GitHub Actions ---
data "aws_iam_policy_document" "github_assume_role" {
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

    # Limit to a specific repo for security:
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

# Policy: allow push/pull to ECR + describe EKS cluster (for kubeconfig)
data "aws_iam_policy_document" "github_actions_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = [
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_cluster_name}"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_inline" {
  name   = "${var.project}-github-actions-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_policy.json
}
