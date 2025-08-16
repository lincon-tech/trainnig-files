# Random suffix for bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for static assets
resource "aws_s3_bucket" "app_assets" {
  bucket = "${var.project_name}-${var.environment}-assets-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-assets"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload a sample file
resource "aws_s3_object" "sample_file" {
  bucket = aws_s3_bucket.app_assets.id
  key    = "sample.txt"
  content = "This is a sample file uploaded by Terraform for the ${var.project_name} ${var.environment} environment."
  
  tags = {
    Name = "sample-file"
  }
}