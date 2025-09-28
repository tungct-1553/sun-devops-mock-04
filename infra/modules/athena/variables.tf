variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket containing data"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket containing data"
  type        = string
}

variable "s3_results_bucket_name" {
  description = "Name of the S3 bucket for Athena results"
  type        = string
}
