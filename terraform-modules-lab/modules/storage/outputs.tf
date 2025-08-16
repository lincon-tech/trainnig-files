output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.app_assets.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app_assets.arn
}

output "bucket_url" {
  description = "URL of the S3 bucket"
  value       = "https://${aws_s3_bucket.app_assets.bucket}.s3.amazonaws.com"
}