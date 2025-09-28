output "data_bucket_name" {
  description = "Name of the S3 bucket for data storage"
  value       = aws_s3_bucket.data.bucket
}

output "data_bucket_arn" {
  description = "ARN of the S3 bucket for data storage"
  value       = aws_s3_bucket.data.arn
}

output "results_bucket_name" {
  description = "Name of the S3 bucket for Athena results"
  value       = aws_s3_bucket.results.bucket
}

output "results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena results"
  value       = aws_s3_bucket.results.arn
}
