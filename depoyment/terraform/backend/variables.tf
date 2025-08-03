variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store the Terraform state file."
  type        = string
  default     = "inkomoko-terraform-state"
}
variable "provider_region" {
  description = "The region for our s3 bucket"
  type        = string
  default     = "us-east-1"
}