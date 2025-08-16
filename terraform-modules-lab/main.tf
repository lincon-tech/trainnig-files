# Configure Terraform and AWS Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Networking Module - Creates VPC, subnets, internet gateway
module "networking" {
  source = "./modules/networking"
  
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = data.aws_availability_zones.available.names
  public_subnet_cidrs = var.public_subnet_cidrs
}

# Storage Module - Creates S3 bucket for static assets
module "storage" {
  source = "./modules/storage"
  
  project_name = var.project_name
  environment  = var.environment
}

# Compute Module - Creates EC2 instances
module "compute" {
  source = "./modules/compute"
  
  project_name          = var.project_name
  environment           = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  instance_type        = var.instance_type
  key_pair_name        = var.key_pair_name
  app_security_group_id = module.networking.app_security_group_id
}

# Load Balancer Module - Creates ALB for high availability
module "load_balancer" {
  source = "./modules/load-balancer"
  
  project_name           = var.project_name
  environment            = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  target_instance_ids   = module.compute.instance_ids
}