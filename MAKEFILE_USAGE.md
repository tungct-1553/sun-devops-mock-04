# Makefile Usage Guide

Dự án này sử dụng **Makefile** để tự động hóa các tác vụ phát triển và triển khai thay vì sử dụng shell scripts.

## 🚀 Quick Start

### 1. Xem tất cả commands có sẵn
```bash
make help
```

### 2. Setup ban đầu
```bash
make setup
source .env
```

### 3. Deploy to development
```bash
make deploy ENV=dev
# Or use shorthand:
make dev-deploy
```

## 📋 Available Commands

### 🔧 Setup & Configuration
| Command | Description |
|---------|-------------|
| `make setup` | Setup ban đầu (tạo S3 bucket, env file, install deps) |
| `make check-tools` | Kiểm tra tools cần thiết (terraform, aws cli, python) |
| `make check-aws` | Kiểm tra AWS credentials |
| `make status` | Hiển thị trạng thái hiện tại |

### 🏗️ Infrastructure Management
| Command | Description |
|---------|-------------|
| `make init ENV=dev` | Initialize Terraform cho environment |
| `make plan ENV=dev` | Xem Terraform plan |
| `make apply ENV=dev` | Apply Terraform changes |
| `make deploy ENV=dev` | Full deployment (init + package + plan + apply) |
| `make destroy ENV=dev` | Destroy infrastructure |
| `make output ENV=dev` | Xem Terraform outputs |

### 🏷️ Shorthand Commands
| Command | Equivalent |
|---------|-------------|
| `make dev-deploy` | `make deploy ENV=dev` |
| `make prod-deploy` | `make deploy ENV=prod` |
| `make dev-plan` | `make plan ENV=dev` |
| `make prod-plan` | `make plan ENV=prod` |
| `make dev-destroy` | `make destroy ENV=dev` |
| `make prod-destroy` | `make destroy ENV=prod` |

### 🐍 Development & Testing
| Command | Description |
|---------|-------------|
| `make package-lambda` | Package Lambda function |
| `make lint` | Run code linting (flake8, pylint) |
| `make format` | Format Python code (black) |
| `make test` | Run unit tests |
| `make clean` | Clean up temporary files |

### 🔍 Debugging & Monitoring
| Command | Description |
|---------|-------------|
| `make invoke-lambda ENV=dev` | Manually invoke Lambda function |
| `make logs ENV=dev` | View Lambda logs |

### ⚙️ CI/CD Helpers
| Command | Description |
|---------|-------------|
| `make ci-validate` | Validate for CI/CD (terraform + lint + test) |
| `make ci-package` | Package for CI/CD |

## 🎯 Common Workflows

### Development Workflow
```bash
# 1. Initial setup (only once)
make setup
source .env

# 2. Make code changes

# 3. Test and validate
make format
make lint  
make test

# 4. Deploy to dev
make dev-deploy

# 5. Test deployment
make invoke-lambda ENV=dev
make logs ENV=dev
```

### Production Deployment
```bash
# 1. Plan production deployment
make prod-plan

# 2. Review plan carefully

# 3. Deploy to production
make prod-deploy

# 4. Verify deployment
make output ENV=prod
make invoke-lambda ENV=prod
```

### Cleanup Development
```bash
make dev-destroy
```

## 🔧 Environment Variables

Makefile sử dụng các environment variables sau:

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `dev` | Target environment (dev/prod) |
| `AWS_REGION` | `us-east-1` | AWS region |
| `PROJECT_NAME` | `data-analytics-report` | Project name |
| `TF_STATE_BUCKET` | Auto-generated | S3 bucket for Terraform state |

Bạn có thể override chúng:
```bash
make deploy ENV=prod AWS_REGION=us-west-2
```

## 🎨 Output Colors

Makefile sử dụng colors để dễ đọc:
- 🟢 **Green**: Success messages
- 🟡 **Yellow**: Info/progress messages  
- 🔴 **Red**: Error messages

## ⚡ Tips & Tricks

### 1. Sử dụng ENV parameter
```bash
# Always specify environment
make deploy ENV=dev
make deploy ENV=prod
```

### 2. Check status trước khi deploy
```bash
make status
make check-tools
make check-aws
```

### 3. Clean up sau khi làm việc
```bash
make clean
```

### 4. Xem outputs sau khi deploy
```bash
make output ENV=dev
```

### 5. Debug với logs
```bash
make logs ENV=dev
```

## 🔍 Troubleshooting

### Make command not found
```bash
# macOS
brew install make

# Ubuntu/Debian
sudo apt-get install make
```

### Permission denied
```bash
# Make sure you're in the right directory
cd path/to/sun-devops-mock-04
```

### AWS credentials not configured
```bash
aws configure
# Or check with:
make check-aws
```

### Terraform state bucket issues
```bash
# Recreate bucket (will be auto-created)
make setup
```

## 📦 Migration from Shell Scripts

Nếu bạn đã quen với shell scripts cũ:

| Old Command | New Command |
|-------------|-------------|
| `./scripts/setup.sh` | `make setup` |
| `./scripts/deploy.sh dev` | `make deploy ENV=dev` |
| `./scripts/deploy.sh prod` | `make deploy ENV=prod` |
| `./scripts/deploy.sh dev plan` | `make plan ENV=dev` |
| `./scripts/deploy.sh dev destroy` | `make destroy ENV=dev` |

## 🤝 Contributing

Khi thêm commands mới vào Makefile:

1. **Add help text**: Sử dụng `## Description` format
2. **Use colors**: GREEN cho success, YELLOW cho info, RED cho error
3. **Add phony targets**: Thêm vào `.PHONY` nếu không tạo files
4. **Test thoroughly**: Test command trước khi commit

Ví dụ:
```makefile
new-command: ## Description of new command
	@echo "$(YELLOW)Info message$(NC)"
	# Command implementation
	@echo "$(GREEN)✅ Success$(NC)"
```
