/*
- Create bucket with force deletion off and lifecycle rules to delete old versions
- add versioning
- add encryption
- add acl`
- add public block
*/
provider "aws" {
  region = var.region
}
locals {
  prefix = "tfstate-${var.environment}"
}
resource "random_string" "random_suffix" {
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = true
}
resource "aws_s3_bucket" "tfstate-bucket" {
  bucket        = "${local.prefix}-bucket-${random_string.random_suffix.result}"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    environment = var.environment
    Name        = "${local.prefix}-bucket"
    CreatedBy   = "Davinci"
  }
}

resource "aws_s3_bucket_versioning" "tfstate-bucket-versioning" {
  bucket = aws_s3_bucket.tfstate-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate-bucket-encryption" {
  bucket = aws_s3_bucket.tfstate-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate_key.arn
    }
    bucket_key_enabled = true
  }
}

# KMS key for S3 bucket encryption
resource "aws_kms_key" "tfstate_key" {
  description             = "KMS key for Terraform state bucket encryption"
  deletion_window_in_days = 7

  tags = {
    environment = var.environment
    Name        = "${local.prefix}-kms-key"
    CreatedBy   = "Davinci"
  }
}

resource "aws_kms_alias" "tfstate_key_alias" {
  name          = "alias/${local.prefix}-tfstate-key"
  target_key_id = aws_kms_key.tfstate_key.key_id
}

# Lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "tfstate-bucket-lifecycle" {
  bucket = aws_s3_bucket.tfstate-bucket.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    # Delete old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Optional: Transition to cheaper storage after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate-bucket-pac" {
  bucket = aws_s3_bucket.tfstate-bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
