# EventBridge Rule
resource "aws_cloudwatch_event_rule" "weekly_report" {
  name                = "${var.project_name}-${var.environment}-weekly-report-rule"
  description         = "Trigger weekly data analysis report"
  schedule_expression = var.schedule_expression
  state               = "ENABLED"

  tags = {
    Name = "${var.project_name}-${var.environment}-weekly-report-rule"
  }
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_report.name
  target_id = "${var.project_name}-${var.environment}-lambda-target"
  arn       = var.lambda_function_arn

  input = jsonencode({
    source      = "eventbridge"
    report_type = "weekly"
    timestamp   = "2024-01-01T00:00:00Z" # This will be replaced at runtime
  })
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_report.arn
}
