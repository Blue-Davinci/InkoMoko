output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
  description = "The name of the s3 bucket"
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "ARN for the created s3 bucket"
}