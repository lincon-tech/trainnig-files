output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "oidc_provider_arn" {
  description = "OIDC Provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "app_role_arn" {
  description = "IAM role ARN for application"
  value       = aws_iam_role.app_role.arn
}