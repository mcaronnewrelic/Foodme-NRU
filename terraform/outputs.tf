output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.foodme.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.foodme.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.foodme.private_ip
}

output "instance_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.foodme.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.foodme.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.foodme_public.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.foodme.id
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.foodme.public_ip}:${var.app_port}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.foodme.public_ip}"
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = var.create_alb ? aws_lb.foodme[0].dns_name : ""
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = var.create_alb ? "http://${aws_lb.foodme[0].dns_name}" : ""
}
