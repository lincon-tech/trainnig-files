# Environment-specific variable values
project_name = "taskmaster"
environment  = "dev"
aws_region   = "us-west-2"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]

# Compute Configuration
instance_type    = "t3.micro"
key_pair_name    = "your-key-pair-name"  # Replace with your key pair

# Application Configuration
app_port = 3000