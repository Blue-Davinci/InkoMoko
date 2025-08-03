output "public_subnets" {
  description = "Map of public subnet IDs in the development environment"
  # public subnet is a map so output it
  value = var.public_subnets
}

output "private_subnets" {
  description = "Map of private subnet IDs in the development environment"
  # private subnet is a map so output it
  value = var.private_subnets

}

output "environment" {
  description = "The environment for which these outputs are defined"
  value       = var.environment
}

output "instance_private_ips" {
  description = "Private IP addresses of instances in the development environment"
  value       = module.compute.instance_private_ips
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "The URL to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}
