variable "alb_name" {
  description = "The name of the ALB."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the ALB will be created."
  type        = string
}

variable "subnet_ids" {
  description = "A list of public subnet IDs for the ALB."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to the ALB."
  type        = map(string)
}

variable "enable_alb_deletion" {
  description = "Enable deletion protection for the ALB."
  type        = bool
  default     = false
}
