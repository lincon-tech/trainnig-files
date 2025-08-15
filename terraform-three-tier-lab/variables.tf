variable "vpc_cidr" { 
default = "10.1.0.0/16" 
}
variable "Pubsubnet1_cidr" { 
default = "10.1.1.0/24" 
}
variable "Pubsubnet2_cidr" { 
default = "10.1.2.0/24" 
}
variable "Prisubnet1_cidr" { 
default = "10.1.3.0/24" 
}
variable "Prisubnet2_cidr" {
default = "10.1.4.0/24"
 }
variable "instance_type" { 
default = "t2.micro" 
}
variable "keyname" { 
default = "k8s"                #Input your own keypair here
}
variable "aws_region" { 
default = "us-east-1" 
}
