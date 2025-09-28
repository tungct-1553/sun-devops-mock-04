# Production environment configuration
project_name = "data-analytics-report"
environment  = "prod"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr                = "10.1.0.0/16"
availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs    = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]

# SES Configuration
ses_domain         = null # Set to your domain if you have one
notification_emails = ["admin@yourcompany.com", "devops@yourcompany.com"]

# EventBridge Configuration
schedule_expression = "cron(0 8 ? * MON *)" # Every Monday at 8:00 AM UTC

# Lambda Configuration
lambda_timeout     = 600  # 10 minutes for production
lambda_memory_size = 1024 # More memory for production
