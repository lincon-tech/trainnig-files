terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  # Uncomment and configure for remote state storage
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "portfoliotracker/terraform.tfstate"
  #   region = "us-west-2"
  #   encrypt = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Project     = "PortfolioTracker"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevSecOps-Team"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

# Configure Kubernetes provider
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Local values for common configurations
locals {
  cluster_name = var.cluster_name
  
  common_tags = {
    Project     = "PortfolioTracker"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  node_group_defaults = {
    disk_size      = 50
    instance_types = ["t3.medium"]
    
    k8s_labels = {
      Environment = var.environment
      NodeGroup   = "main"
    }
    
    additional_tags = local.common_tags
  }
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.eks.arn

  tags = local.common_tags
}