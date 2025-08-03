output "s3_bucket_name" {
  value       = aws_s3_bucket.tfstate-bucket.bucket
  description = "The name of the s3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.tfstate-bucket.arn
  description = "ARN for the created s3 bucket"
}

output "kms_key_id" {
  value       = aws_kms_key.tfstate_key.key_id
  description = "The ID of the KMS key used for S3 encryption"
}

output "kms_key_arn" {
  value       = aws_kms_key.tfstate_key.arn
  description = "The ARN of the KMS key used for S3 encryption"
}
