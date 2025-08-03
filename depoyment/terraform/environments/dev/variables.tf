variable "bucket_name" {
  description = "The name of the S3 bucket to store Terraform state files."
  type        = string
}

variable "bucket_region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to assign to the S3 bucket."
  type        = map(string)
  default = {
    Environment = "Dev"
    ManagedBy   = "InkoMoko"
    CreatedBy   = "InkoMoko"
  }
}

variable "public_subnets" {
  description = "A map of public subnet CIDR blocks."
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "private_subnets" {
  description = "A map of private subnet CIDR blocks."
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

variable "vpc_cidr" {
  description = "cidr range for the VPC"
  type        = string
}
