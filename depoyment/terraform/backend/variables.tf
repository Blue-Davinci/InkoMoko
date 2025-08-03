variable "bucket_name" {
  description = "The name of the S3 bucket to store Terraform state files."
  type        = string
  default     = "tfstate-dev-bucket-test-123"
}

variable "environment" {
  description = "The environment for which the Terraform state is being managed (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
  default     = "us-east-1"
}
