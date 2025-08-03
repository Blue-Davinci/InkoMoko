# create the s3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_bucket_name
  /* 
  Note: We are using the force_destroy argument to allow the bucket to be deleted even if it contains objects.
    This is useful for development and testing purposes, but in production, you should be careful with this setting.
    Actually, it is not recommended to use force_destroy in production environments, as it can lead to data loss.
    If you want to keep the objects in the bucket, you should remove this argument or set it to false.
  */
  force_destroy = true
  /*
    Same as the above seeting, this is not recommended in production environments.
    # It is better to use the lifecycle block to prevent the bucket from being destroyed if it contains objects.
    
    */
  lifecycle {
    prevent_destroy = false
  }

}

# We enable versioning for the bucket
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# We secure the bucket with server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

# For an added benefit and also minimize cost, we enable deletion of old versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    filter {
      prefix = ""
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7 # Abort incomplete uploads after 7 days
    }
    
  }
}