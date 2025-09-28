# SES Domain Identity (optional)
resource "aws_ses_domain_identity" "main" {
  count  = var.domain_name != null ? 1 : 0
  domain = var.domain_name
}

# SES Email Identity (for individual emails)
resource "aws_ses_email_identity" "notification_emails" {
  count = length(var.notification_emails)
  email = var.notification_emails[count.index]
}

# SES Configuration Set (for tracking)
resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-${var.environment}-config-set"

  delivery_options {
    tls_policy = "Require"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ses-config-set"
  }
}

# SES Event Destination for CloudWatch
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "${var.project_name}-${var.environment}-cloudwatch"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# CloudWatch Log Group for SES events
resource "aws_cloudwatch_log_group" "ses_logs" {
  name              = "/aws/ses/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-${var.environment}-ses-logs"
  }
}
