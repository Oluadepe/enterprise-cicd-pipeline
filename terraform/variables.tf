variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Name prefix"
  default     = "cicd-demo"
}

variable "ecr_repo_name" {
  type        = string
  description = "ECR repository name"
  default     = "demo-api"
}

variable "github_org" {
  type        = string
  description = "GitHub org/user that owns the repo"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "eks_cluster_name" {
  type        = string
  description = "Existing EKS cluster name to deploy into"
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace for deployment"
  default     = "demo"
}
