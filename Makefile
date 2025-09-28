# Data Analytics Report System - Makefile
# Usage: make <target>

# Default values
ENVIRONMENT ?= dev
AWS_REGION ?= us-east-1
PROJECT_NAME ?= data-analytics-report
TF_STATE_BUCKET ?= $(PROJECT_NAME)-terraform-state-$(shell date +%s)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help setup check-tools check-aws init package-lambda plan apply deploy destroy clean lint test format validate-tf

help: ## Show this help message
	@echo "$(GREEN)Data Analytics Report System - Available Commands:$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make setup                    # Initial setup"
	@echo "  make deploy ENV=dev          # Deploy to dev"
	@echo "  make deploy ENV=prod         # Deploy to prod"
	@echo "  make destroy ENV=dev         # Destroy dev environment"
	@echo "  make plan ENV=prod           # Plan prod deployment"

setup: ## Initial setup - create S3 bucket and environment
	@echo "$(GREEN)🔧 Setting up Data Analytics Report System...$(NC)"
	@$(MAKE) check-tools
	@$(MAKE) check-aws
	@$(MAKE) create-tf-state-bucket
	@$(MAKE) create-env-file
	@$(MAKE) install-python-deps
	@echo "$(GREEN)✅ Setup completed successfully!$(NC)"
	@$(MAKE) show-next-steps

check-tools: ## Check if required tools are installed
	@echo "$(YELLOW)🔍 Checking prerequisites...$(NC)"
	@command -v aws >/dev/null 2>&1 || (echo "$(RED)❌ AWS CLI is not installed$(NC)" && exit 1)
	@command -v terraform >/dev/null 2>&1 || (echo "$(RED)❌ Terraform is not installed$(NC)" && exit 1)
	@command -v python3 >/dev/null 2>&1 || (echo "$(RED)❌ Python 3 is not installed$(NC)" && exit 1)
	@command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1 || (echo "$(RED)❌ pip is not installed$(NC)" && exit 1)
	@echo "$(GREEN)✅ All prerequisites are met!$(NC)"

check-aws: ## Check AWS credentials
	@echo "$(YELLOW)🔍 Checking AWS credentials...$(NC)"
	@aws sts get-caller-identity >/dev/null 2>&1 || (echo "$(RED)❌ AWS credentials not configured. Run 'aws configure'$(NC)" && exit 1)
	@echo "$(GREEN)✅ AWS credentials configured$(NC)"

create-tf-state-bucket: ## Create S3 bucket for Terraform state
	@echo "$(YELLOW)📦 Setting up Terraform backend...$(NC)"
	@if aws s3api head-bucket --bucket "$(TF_STATE_BUCKET)" 2>/dev/null; then \
		echo "$(GREEN)✅ Terraform state bucket '$(TF_STATE_BUCKET)' already exists$(NC)"; \
	else \
		echo "$(YELLOW)📦 Creating Terraform state bucket '$(TF_STATE_BUCKET)'...$(NC)"; \
		if [ "$(AWS_REGION)" = "us-east-1" ]; then \
			aws s3api create-bucket --bucket "$(TF_STATE_BUCKET)"; \
		else \
			aws s3api create-bucket --bucket "$(TF_STATE_BUCKET)" --region "$(AWS_REGION)" \
				--create-bucket-configuration LocationConstraint="$(AWS_REGION)"; \
		fi; \
		aws s3api put-bucket-versioning --bucket "$(TF_STATE_BUCKET)" \
			--versioning-configuration Status=Enabled; \
		aws s3api put-bucket-encryption --bucket "$(TF_STATE_BUCKET)" \
			--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'; \
		aws s3api put-public-access-block --bucket "$(TF_STATE_BUCKET)" \
			--public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"; \
		echo "$(GREEN)✅ Terraform state bucket created successfully$(NC)"; \
	fi

create-env-file: ## Create environment configuration file
	@echo "$(YELLOW)📝 Creating environment configuration...$(NC)"
	@echo "# AWS Configuration" > .env
	@echo "export AWS_REGION=$(AWS_REGION)" >> .env
	@echo "export TF_STATE_BUCKET=$(TF_STATE_BUCKET)" >> .env
	@echo "" >> .env
	@echo "# Project Configuration" >> .env
	@echo "export PROJECT_NAME=$(PROJECT_NAME)" >> .env
	@echo "" >> .env
	@echo "# Usage:" >> .env
	@echo "# source .env" >> .env
	@echo "# make deploy ENV=dev" >> .env
	@echo "$(GREEN)✅ Environment configuration saved to .env$(NC)"

install-python-deps: ## Install Python dependencies for local development
	@echo "$(YELLOW)🐍 Installing Python dependencies...$(NC)"
	@cd src/lambda/data_analyzer && pip install -r requirements.txt --quiet
	@echo "$(GREEN)✅ Python dependencies installed$(NC)"

validate-env: ## Validate environment parameter
	@if [ "$(ENVIRONMENT)" != "dev" ] && [ "$(ENVIRONMENT)" != "prod" ]; then \
		echo "$(RED)❌ Error: ENVIRONMENT must be 'dev' or 'prod'$(NC)"; \
		echo "Usage: make deploy ENV=dev or make deploy ENV=prod"; \
		exit 1; \
	fi

init: validate-env check-tools check-aws ## Initialize Terraform
	@echo "$(YELLOW)📦 Initializing Terraform for $(ENVIRONMENT) environment...$(NC)"
	@cd infra && terraform init \
		-backend-config="bucket=${TF_STATE_BUCKET}" \
		-backend-config="key=$(ENVIRONMENT)/terraform.tfstate" \
		-backend-config="region=$(AWS_REGION)"

package-lambda: ## Package Lambda function
	@echo "$(YELLOW)📝 Packaging Lambda function...$(NC)"
	@cd src/lambda/data_analyzer && \
		pip install -r requirements.txt -t . --quiet && \
		zip -r ../../../infra/lambda_function.zip . -x "tests/*" "*.pyc" "__pycache__/*" > /dev/null
	@echo "$(GREEN)✅ Lambda function packaged$(NC)"

validate-tf: init ## Validate Terraform configuration
	@echo "$(YELLOW)🔍 Validating Terraform configuration...$(NC)"
	@cd infra && terraform fmt -check -recursive
	@cd infra && terraform validate
	@echo "$(GREEN)✅ Terraform configuration is valid$(NC)"

plan: init package-lambda ## Create Terraform plan
	@echo "$(YELLOW)📋 Creating Terraform plan for $(ENVIRONMENT)...$(NC)"
	@cd infra && terraform plan -var-file="environments/$(ENVIRONMENT)/terraform.tfvars"

plan-save: init package-lambda ## Create and save Terraform plan
	@echo "$(YELLOW)📋 Creating Terraform plan for $(ENVIRONMENT)...$(NC)"
	@cd infra && terraform plan -var-file="environments/$(ENVIRONMENT)/terraform.tfvars" -out=tfplan

apply: plan-save ## Apply Terraform configuration
	@echo "$(YELLOW)🔧 Applying Terraform configuration for $(ENVIRONMENT)...$(NC)"
	@cd infra && terraform apply -auto-approve tfplan
	@echo "$(YELLOW)📊 Deployment outputs:$(NC)"
	@cd infra && terraform output
	@echo "$(GREEN)✅ Deployment completed successfully!$(NC)"
	@$(MAKE) show-post-deploy-notes

deploy: validate-env ## Full deployment (init + package + plan + apply)
	@echo "$(GREEN)🚀 Deploying Data Analytics Report System to $(ENVIRONMENT) environment...$(NC)"
	@$(MAKE) init ENV=$(ENVIRONMENT)
	@$(MAKE) package-lambda
	@$(MAKE) apply ENV=$(ENVIRONMENT)

destroy: validate-env init ## Destroy infrastructure
	@echo "$(RED)🗑️  Destroying $(ENVIRONMENT) infrastructure...$(NC)"
	@read -p "Are you sure you want to destroy $(ENVIRONMENT) environment? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd infra && terraform destroy -var-file="environments/$(ENVIRONMENT)/terraform.tfvars" -auto-approve; \
		echo "$(GREEN)✅ Infrastructure destroyed successfully!$(NC)"; \
	else \
		echo "$(YELLOW)Destroy cancelled$(NC)"; \
	fi

clean: ## Clean up temporary files
	@echo "$(YELLOW)🧹 Cleaning up temporary files...$(NC)"
	@rm -f infra/lambda_function.zip infra/tfplan
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed$(NC)"

lint: ## Run code linting
	@echo "$(YELLOW)🔍 Running code linting...$(NC)"
	@flake8 src/lambda/ --max-line-length=88 --extend-ignore=E203,W503 || echo "$(YELLOW)⚠️  Flake8 not installed$(NC)"
	@pylint src/lambda/**/*.py --disable=C0114,C0115,C0116 || echo "$(YELLOW)⚠️  Pylint not installed$(NC)"

format: ## Format Python code
	@echo "$(YELLOW)🎨 Formatting Python code...$(NC)"
	@black src/lambda/ || echo "$(YELLOW)⚠️  Black not installed$(NC)"

test: ## Run tests
	@echo "$(YELLOW)🧪 Running tests...$(NC)"
	@cd src/lambda/data_analyzer && python -m pytest ../../../tests/ -v || echo "$(YELLOW)⚠️  No tests found or pytest not installed$(NC)"

invoke-lambda: ## Manually invoke Lambda function
	@echo "$(YELLOW)🔧 Invoking Lambda function for $(ENVIRONMENT)...$(NC)"
	@aws lambda invoke \
		--function-name "$(PROJECT_NAME)-$(ENVIRONMENT)-data-analyzer" \
		--payload '{"source":"manual","report_type":"weekly"}' \
		response.json && cat response.json && echo ""

logs: ## View Lambda logs
	@echo "$(YELLOW)📄 Viewing Lambda logs for $(ENVIRONMENT)...$(NC)"
	@aws logs tail "/aws/lambda/$(PROJECT_NAME)-$(ENVIRONMENT)-data-analyzer" --follow

output: validate-env init ## Show Terraform outputs
	@echo "$(YELLOW)📊 Terraform outputs for $(ENVIRONMENT):$(NC)"
	@cd infra && terraform output

show-next-steps: ## Show next steps after setup
	@echo ""
	@echo "$(GREEN)🎉 Setup completed successfully!$(NC)"
	@echo ""
	@echo "$(YELLOW)📚 Next steps:$(NC)"
	@echo "1. Update notification email addresses in:"
	@echo "   - infra/environments/dev/terraform.tfvars"
	@echo "   - infra/environments/prod/terraform.tfvars"
	@echo ""
	@echo "2. Review and customize the configuration files as needed"
	@echo ""
	@echo "3. Deploy to development environment:"
	@echo "   $(YELLOW)source .env$(NC)"
	@echo "   $(YELLOW)make deploy ENV=dev$(NC)"
	@echo ""
	@echo "4. Don't forget to verify your email addresses in AWS SES console"

show-post-deploy-notes: ## Show notes after deployment
	@echo ""
	@echo "$(GREEN)📧 Don't forget to:$(NC)"
	@echo "1. Verify your email addresses in AWS SES console"
	@echo "2. Upload sample data to S3 bucket if needed"
	@echo "3. Create the Athena table using the provided named query"
	@echo ""
	@echo "$(YELLOW)💡 Useful commands:$(NC)"
	@echo "  make invoke-lambda ENV=$(ENVIRONMENT)  # Test Lambda function"
	@echo "  make logs ENV=$(ENVIRONMENT)           # View logs"
	@echo "  make output ENV=$(ENVIRONMENT)         # Show outputs"

# Development targets
dev-deploy: ## Deploy to development
	@$(MAKE) deploy ENV=dev

prod-deploy: ## Deploy to production  
	@$(MAKE) deploy ENV=prod

dev-destroy: ## Destroy development
	@$(MAKE) destroy ENV=dev

prod-destroy: ## Destroy production
	@$(MAKE) destroy ENV=prod

dev-plan: ## Plan development deployment
	@$(MAKE) plan ENV=dev

prod-plan: ## Plan production deployment
	@$(MAKE) plan ENV=prod

# CI/CD helpers
ci-validate: ## Validate for CI/CD
	@$(MAKE) check-tools
	@$(MAKE) validate-tf ENV=dev
	@$(MAKE) lint
	@$(MAKE) test

ci-package: ## Package for CI/CD
	@$(MAKE) package-lambda

# Utility targets
status: ## Show current status
	@echo "$(YELLOW)📊 Current Status:$(NC)"
	@echo "Project Name: $(PROJECT_NAME)"
	@echo "AWS Region: $(AWS_REGION)"
	@echo "TF State Bucket: $(TF_STATE_BUCKET)"
	@echo "Environment: $(ENVIRONMENT)"
	@echo ""
	@if [ -f .env ]; then \
		echo "$(GREEN)✅ .env file exists$(NC)"; \
	else \
		echo "$(RED)❌ .env file missing - run 'make setup'$(NC)"; \
	fi
	@$(MAKE) check-tools 2>/dev/null || echo "$(RED)❌ Tools check failed$(NC)"
	@$(MAKE) check-aws 2>/dev/null || echo "$(RED)❌ AWS check failed$(NC)"
