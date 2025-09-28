output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.data_analyzer.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.data_analyzer.function_name
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.data_analyzer.invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}
