variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Lambda will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Lambda"
  type        = list(string)
}

variable "athena_database_name" {
  description = "Name of the Athena database"
  type        = string
}

variable "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket containing data"
  type        = string
}

variable "s3_results_bucket_name" {
  description = "Name of the S3 bucket for Athena results"
  type        = string
}

variable "ses_identity_arn" {
  description = "ARN of the SES identity"
  type        = string
}

variable "notification_emails" {
  description = "List of email addresses to receive notifications"
  type        = list(string)
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}
