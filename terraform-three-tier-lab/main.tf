provider "aws" {
  region = var.aws_region
}

# AMI via SSM Parameter (Amazon Linux 2)
data "aws_ssm_parameter" "instance_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# -----------------------------
# VPC & Networking
# -----------------------------
resource "aws_vpc" "three_tier_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "Three-tier-vpc" }
}

resource "aws_internet_gateway" "three_tier_igw" {
  vpc_id = aws_vpc.three_tier_vpc.id
  tags   = { Name = "Three-tier-IGW" }
}

# Subnets
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = var.Pubsubnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags                    = { Name = "Three_tier_public_subnet01" }
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = var.Pubsubnet2_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags                    = { Name = "Three_tier_public_subnet02" }
}

resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = var.Prisubnet1_cidr
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags                    = { Name = "Three_tier_private_subnet01" }
}

resource "aws_subnet" "private_1b" {
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = var.Prisubnet2_cidr
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags                    = { Name = "Three_tier_private_subnet02" }
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.three_tier_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three_tier_igw.id
  }
  tags = { Name = "route-to-internet" }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

# NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1b.id
  tags          = { Name = "gw-NAT" }
  depends_on    = [aws_internet_gateway.three_tier_igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.three_tier_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "No-route-to-internet" }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
# Security Groups
# -----------------------------
# Frontend ALB
resource "aws_security_group" "external_alb_sg" {
  name        = "External_ALB_SG"
  description = "Allow HTTP/HTTPS from anywhere"
  vpc_id      = aws_vpc.three_tier_vpc.id

  ingress { 
    from_port = 80  
    to_port = 80  
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress { 
    from_port = 443 
    to_port = 443 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  egress  { 
    from_port = 0   
    to_port = 0  
     protocol = "-1"  
     cidr_blocks = ["0.0.0.0/0"] 
     }

  tags = { Name = "External_ALB_SG" }
}

# Backend NLB (TCP 3000)
resource "aws_security_group" "internal_nlb_sg" {
  name        = "Internal_NLB_SG"
  description = "Allow TCP/3000 from anywhere (adjust as needed)"
  vpc_id      = aws_vpc.three_tier_vpc.id

  ingress { 
    from_port = 3000 
    to_port = 3000 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  egress  { 
    from_port = 0    
    to_port = 0    
    protocol = "-1"  
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = { Name = "Internal_NLB_SG" }
}

# EC2 instances
resource "aws_security_group" "instances_sg" {
  name        = "Instances-SG"
  description = "Allow HTTP/HTTPS/SSH to instances"
  vpc_id      = aws_vpc.three_tier_vpc.id

  ingress { 
    from_port = 80  
    to_port = 80  
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress { 
    from_port = 443 
    to_port = 443 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress { 
    from_port = 22  
    to_port = 22  
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
    

  egress  { 
    from_port = 0  
    to_port = 0   
    protocol = "-1"  
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = { Name = "Instances-SG" }
}

# Bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "Bastion Host Security Group"
  description = "Bastion Host Security Group"
  vpc_id      = aws_vpc.three_tier_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.3.0/24", "10.1.4.0/24", "0.0.0.0/0"]
  }

  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = { Name = "Bastion_Host_SG" }
}

# -----------------------------
# Load Balancers (Modern)
# -----------------------------
# FRONTEND: Internet-facing ALB (HTTP :80)
resource "aws_lb" "frontend_alb" {
  name               = "frontend-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.external_alb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]

  tags = { Name = "Frontend-ALB" }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.three_tier_vpc.id
  target_type = "instance"

  health_check {
    enabled  = true
    protocol = "HTTP"
    path     = "/"
    port     = "traffic-port"
  }

  tags = { Name = "Frontend-tg" }
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# BACKEND: Internal NLB (TCP :3000)
resource "aws_lb" "backend_nlb" {
  name               = "backend-nlb"
  load_balancer_type = "network"
  internal           = true
  # NLBs can have SGs in some contexts with AWS GWLB/NLB + SGs; for simplicity omit SGs here (or attach if needed via ALB-style).
  subnets = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]

  tags = { Name = "Backend-NLB" }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg"
  port        = 3000
  protocol    = "TCP"
  vpc_id      = aws_vpc.three_tier_vpc.id
  target_type = "instance"

  # For TCP, use TCP health checks on the same port
  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }

  tags = { Name = "Backend-tg" }
}

resource "aws_lb_listener" "backend_tcp" {
  load_balancer_arn = aws_lb.backend_nlb.arn
  port              = 3000
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# -----------------------------
# Launch Templates
# -----------------------------
resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "Frontend-LT-"
  image_id      = data.aws_ssm_parameter.instance_ami.value
  instance_type = var.instance_type
  key_name      = var.keyname

  vpc_security_group_ids = [aws_security_group.instances_sg.id]

  # If you need explicit user_data, base64 is required in LT
  user_data = filebase64("${path.module}/scripts.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Frontend"
    }
  }
}

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "Backend-LT-"
  image_id      = data.aws_ssm_parameter.instance_ami.value
  instance_type = var.instance_type
  key_name      = var.keyname

  vpc_security_group_ids = [aws_security_group.instances_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Backend"
    }
  }
}

resource "aws_launch_template" "bastion_lt" {
  name_prefix   = "Bastion-LT-"
  image_id      = data.aws_ssm_parameter.instance_ami.value
  instance_type = var.instance_type
  key_name      = var.keyname

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Bastion-Host"
    }
  }
}

# -----------------------------
# Auto Scaling Groups
# -----------------------------
resource "aws_autoscaling_group" "frontend_asg" {
  name                      = "Frontend-ASG"
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 2
  vpc_zone_identifier       = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
  target_group_arns         = [aws_lb_target_group.frontend_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  metrics_granularity       = "1Minute"

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "Frontend"
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "backend_asg" {
  name                      = "Backend-ASG"
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 2
  vpc_zone_identifier       = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  target_group_arns         = [aws_lb_target_group.backend_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  metrics_granularity       = "1Minute"

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "Backend"
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "bastion_asg" {
  name                = "Bastion-ASG"
  min_size            = 1
  desired_capacity    = 1
  max_size            = 1
  vpc_zone_identifier = [aws_subnet.public_1b.id]

  launch_template {
    id      = aws_launch_template.bastion_lt.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  metrics_granularity = "1Minute"

  tag {
    key                 = "Name"
    value               = "Bastion-Host"
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}

# -----------------------------
# Simple step scaling policies (unchanged semantics)
# -----------------------------
resource "aws_autoscaling_policy" "frontend_policy_up" {
  name                   = "Frontend_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend_asg.name
}

resource "aws_autoscaling_policy" "backend_policy_up" {
  name                   = "Backend_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
}

resource "aws_autoscaling_policy" "frontend_policy_down" {
  name                   = "Frontend_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend_asg.name
}

resource "aws_autoscaling_policy" "backend_policy_down" {
  name                   = "Backend_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
}
