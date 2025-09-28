# Provider configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Sẽ được cấu hình qua backend-config
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# S3 Module for data storage
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
}

# Athena Module
module "athena" {
  source = "./modules/athena"
  
  project_name    = var.project_name
  environment     = var.environment
  s3_bucket_name  = module.s3.data_bucket_name
  s3_bucket_arn   = module.s3.data_bucket_arn
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"
  
  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  athena_database_name   = module.athena.database_name
  athena_workgroup_name  = module.athena.workgroup_name
  s3_bucket_name         = module.s3.data_bucket_name
  s3_results_bucket_name = module.s3.results_bucket_name
  ses_identity_arn       = module.ses.identity_arn
  notification_emails    = var.notification_emails
}

# SES Module
module "ses" {
  source = "./modules/ses"
  
  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.ses_domain
  
  # SES cần ở US East 1 cho một số tính năng
  providers = {
    aws = aws
  }
}

# EventBridge Module
module "eventbridge" {
  source = "./modules/eventbridge"
  
  project_name          = var.project_name
  environment           = var.environment
  lambda_function_arn   = module.lambda.function_arn
  lambda_function_name  = module.lambda.function_name
  schedule_expression   = var.schedule_expression
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name         = var.project_name
  environment          = var.environment
  lambda_function_name = module.lambda.function_name
  notification_emails  = var.notification_emails
}
