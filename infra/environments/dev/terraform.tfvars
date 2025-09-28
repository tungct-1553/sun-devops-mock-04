# Development environment configuration
project_name = "data-analytics-report"
environment  = "dev"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr                = "10.0.0.0/16"
availability_zones      = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.11.0/24", "10.0.12.0/24"]

# SES Configuration
ses_domain         = null # Set to your domain if you have one
notification_emails = ["your-email@example.com"] # Update this

# EventBridge Configuration
schedule_expression = "cron(0 8 ? * MON *)" # Every Monday at 8:00 AM UTC

# Lambda Configuration
lambda_timeout     = 300
lambda_memory_size = 512
