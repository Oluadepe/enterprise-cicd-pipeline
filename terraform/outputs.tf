output "ecr_repository_url" {
  value       = aws_ecr_repository.repo.repository_url
  description = "ECR repository URL (use as GitHub secret ECR_REPOSITORY)"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM role ARN for GitHub OIDC (use as GitHub secret AWS_ROLE_ARN)"
}
