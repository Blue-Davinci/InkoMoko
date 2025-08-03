output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.ec2_launch_template.id
}

output "security_group_id" {
  description = "The ID of the EC2 security group"
  value       = aws_security_group.asg_ec2_sg.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "instance_private_ips" {
  description = "Private IP addresses of instances in the ASG (for monitoring/debugging)"
  value       = data.aws_instances.asg_instances.private_ips
}

output "instance_ids" {
  description = "Instance IDs in the ASG (for monitoring/debugging)"
  value       = data.aws_instances.asg_instances.ids
}

# Data source to get current instances in the ASG
data "aws_instances" "asg_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.asg.name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}
