# Data Analytics Report System

## Development Environment

## Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0 
- Python >= 3.9
- Make sure your AWS account has the necessary service limits

## Quick Start

1. **Initial Setup**
   ```bash
   make setup
   source .env
   ```

2. **Update Configuration**
   - Edit `infra/environments/dev/terraform.tfvars`
   - Set your email address in `notification_emails`

3. **Deploy**
   ```bash
   make deploy ENV=dev
   ```

4. **Verify SES Email**
   - Go to AWS SES Console
   - Verify your email addresses

## Development Workflow

### Local Testing
```bash
make test
# Or run manually:
cd src/lambda/data_analyzer
python -m pytest tests/ -v
```

### Code Quality
```bash
# Format and lint code
make format
make lint

# Or run manually:
black src/lambda/
flake8 src/lambda/
pylint src/lambda/**/*.py
```

### Infrastructure Changes
```bash
# Plan changes
make plan ENV=dev

# Apply changes
make deploy ENV=dev

# Destroy (cleanup)
make destroy ENV=dev
```

## Debugging

### Lambda Logs
```bash
make logs ENV=dev
# Or manually:
aws logs tail /aws/lambda/data-analytics-report-dev-data-analyzer --follow
```

### Manual Invocation
```bash
make invoke-lambda ENV=dev
# Or manually:
aws lambda invoke \
  --function-name data-analytics-report-dev-data-analyzer \
  --payload '{"source":"manual"}' \
  response.json && cat response.json
```

### Athena Queries
1. Go to AWS Athena Console
2. Select workgroup: `data-analytics-report-dev-workgroup`  
3. Test queries against `sales_data` table

## Environment Variables

The following environment variables are used:

- `AWS_REGION`: AWS region for deployment
- `TF_STATE_BUCKET`: S3 bucket for Terraform state
- `PROJECT_NAME`: Project name for resource naming

## Common Issues

1. **SES Sandbox Mode**: New AWS accounts are in SES sandbox mode - you can only send to verified email addresses
2. **Lambda Cold Starts**: First invocation may be slower
3. **Athena Data Location**: Make sure sample data is uploaded to correct S3 location

## Contributing

1. Follow existing code patterns
2. Add tests for new functionality
3. Update documentation
4. Test in development environment before production
