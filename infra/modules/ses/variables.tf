variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for SES (optional)"
  type        = string
  default     = null
}

variable "notification_emails" {
  description = "List of email addresses for SES identities"
  type        = list(string)
  default     = []
}
