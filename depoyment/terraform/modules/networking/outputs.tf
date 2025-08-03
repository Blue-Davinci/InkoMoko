output "vpc_id" {
  value       = aws_vpc.main_vpc.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value = {
    for k, v in aws_subnet.public_subnets : k => v.id
  }
  description = "A map of public subnet IDs with the same keys as input"
}

output "private_subnet_ids" {
  value = {
    for k, v in aws_subnet.private_subnets : k => v.id
  }
  description = "A map of private subnet IDs with the same keys as input"
}

output "public_subnet_ids_list" {
  value       = values(aws_subnet.public_subnets)[*].id
  description = "A list of public subnet IDs (for ALB)"
}

output "private_subnet_ids_list" {
  value       = values(aws_subnet.private_subnets)[*].id
  description = "A list of private subnet IDs (for EC2 instances)"
}
