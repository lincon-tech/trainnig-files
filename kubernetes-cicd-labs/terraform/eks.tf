module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  # Security configurations
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Enable logging for security monitoring
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Node groups
  eks_managed_node_groups = {
    main = {
      name = "main-nodes"
      
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Security configurations
      enable_bootstrap_user_data = true
      user_data = base64encode(<<-EOF
        #!/bin/bash
        /etc/eks/bootstrap.sh ${var.cluster_name}
        # Install security tools
        yum update -y
        yum install -y amazon-cloudwatch-agent
      EOF
      )

      # Use launch template for additional security
      create_launch_template = true
      launch_template_name = "${var.cluster_name}-node-template"
      
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 50
            volume_type = "gp3"
            encrypted   = true
            kms_key_id  = aws_kms_key.eks.arn
          }
        }
      }

      tags = {
        Environment = var.environment
        Security = "encrypted"
      }
    }
  }

  # OIDC Provider for service accounts
  enable_irsa = true

  tags = {
    Environment = var.environment
  }
}

# KMS Key for encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-encryption-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-encryption-key"
  target_key_id = aws_kms_key.eks.key_id
}