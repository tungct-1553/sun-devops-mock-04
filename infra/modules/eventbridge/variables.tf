variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to trigger"
  type        = string
}

variable "schedule_expression" {
  description = "Schedule expression for EventBridge rule"
  type        = string
  default     = "cron(0 8 ? * MON *)" # Every Monday at 8:00 AM UTC
}
