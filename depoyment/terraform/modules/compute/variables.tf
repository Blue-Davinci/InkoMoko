variable "vpc_id" {
  description = "The ID of the VPC to launch the instance in"
  type        = string
}

# vpc_cidr block
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

# ALB sg id
variable "alb_sg_id" {
  description = "The security group ID of the ALB"
  type        = string
}

# instance prefix
variable "instance_prefix" {
  description = "The prefix for the EC2 instance name"
  type        = string
}

# ami
variable "instance_ami" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

# instance type
variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
}

# private subnet ids
variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the EC2 instances"
  type        = list(string)
}

# ALB target group ARN
variable "target_group_arn" {
  description = "The target group ARN of the ALB"
  type        = string
}

# target_tracking_resource_label
variable "target_tracking_resource_label" {
  description = "The resource label for the target tracking scaling policy"
  type        = string
}

# docker_image_url
variable "docker_image_url" {
  description = "The URL of the Docker image to use in the user data script"
  type        = string
  default     = "public.ecr.aws/inkomoko/inkomoko:latest"
}
