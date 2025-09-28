# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# S3 Outputs
output "data_bucket_name" {
  description = "Name of the S3 bucket for data storage"
  value       = module.s3.data_bucket_name
}

output "results_bucket_name" {
  description = "Name of the S3 bucket for Athena results"
  value       = module.s3.results_bucket_name
}

# Lambda Outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

# Athena Outputs
output "athena_database_name" {
  description = "Name of the Athena database"
  value       = module.athena.database_name
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = module.athena.workgroup_name
}

# SES Outputs
output "ses_identity_arn" {
  description = "ARN of the SES identity"
  value       = module.ses.identity_arn
}

# EventBridge Outputs
output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = module.eventbridge.rule_arn
}
