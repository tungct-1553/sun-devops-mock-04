output "identity_arn" {
  description = "ARN of the SES identity (domain or email)"
  value = var.domain_name != null ? (
    length(aws_ses_domain_identity.main) > 0 ? aws_ses_domain_identity.main[0].arn : ""
  ) : (
    length(aws_ses_email_identity.notification_emails) > 0 ? 
    aws_ses_email_identity.notification_emails[0].arn : ""
  )
}

output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = var.domain_name != null ? aws_ses_domain_identity.main[0].arn : null
}

output "email_identities" {
  description = "List of SES email identity ARNs"
  value       = aws_ses_email_identity.notification_emails[*].arn
}

output "configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.main.name
}
