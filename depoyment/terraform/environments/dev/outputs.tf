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
