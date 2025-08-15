output "frontend_alb_dns_name" {
  description = "DNS name of the frontend ALB"
  value       = aws_lb.frontend_alb.dns_name
}


output "backend_nlb_dns_name" {
  description = "DNS name of the backend NLB"
  value       = aws_lb.backend_nlb.dns_name
}

output "bastion_asg_name" {
  description = "Name of the bastion Auto Scaling Group"
  value       = aws_autoscaling_group.bastion_asg.name
}