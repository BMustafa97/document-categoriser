# Makefile for Docuument Categoriser App Terraform Infrastructure
# Provides convenient commands for managing infrastructure

.PHONY: help init plan apply destroy validate format check clean status

# Default target
help: ## Show available commands
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage examples:"
	@echo "  make init     # Initialize Terraform"
	@echo "  make plan     # Show planned changes"
	@echo "  make apply    # Apply changes"
	@echo "  make destroy  # Destroy infrastructure"

init: ## Initialize Terraform and download providers
	@echo "🚀 Initializing Terraform..."
	terraform init
	@echo "✅ Terraform initialized"

validate: ## Validate Terraform configuration
	@echo "🔍 Validating configuration..."
	terraform validate
	@echo "✅ Configuration is valid"

format: ## Format Terraform files
	@echo "📝 Formatting Terraform files..."
	terraform fmt -recursive
	@echo "✅ Files formatted"

plan: validate ## Show planned infrastructure changes
	@echo "📋 Planning infrastructure changes..."
	terraform plan -out=tfplan
	@echo "✅ Plan completed (saved to tfplan)"

apply: ## Apply infrastructure changes
	@echo "🚀 Applying infrastructure changes..."
	@if [ -f tfplan ]; then \
		terraform apply tfplan; \
		rm tfplan; \
	else \
		terraform apply; \
	fi
	@echo "✅ Infrastructure applied"

destroy: ## Destroy all infrastructure (with confirmation)
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read
	terraform destroy
	@echo "🗑️  Infrastructure destroyed"

status: ## Show current infrastructure status
	@echo "📊 Current infrastructure status:"
	@terraform state list 2>/dev/null || echo "No infrastructure deployed"

outputs: ## Show Terraform outputs
	@echo "📤 Infrastructure outputs:"
	@terraform output -json 2>/dev/null | jq '.' || terraform output

check: validate format ## Run all checks (validate and format)
	@echo "✅ All checks passed"

clean: ## Clean up temporary files
	@echo "🧹 Cleaning up temporary files..."
	rm -f tfplan
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	@echo "✅ Cleanup completed"

refresh: ## Refresh Terraform state
	@echo "🔄 Refreshing Terraform state..."
	terraform refresh
	@echo "✅ State refreshed"

upgrade: ## Upgrade providers to latest versions
	@echo "⬆️  Upgrading providers..."
	terraform init -upgrade
	@echo "✅ Providers upgraded"

# Development helpers
dev-plan: ## Quick plan for development environment
	@terraform plan -var="environment=dev" -var="enable_deletion_protection=false"

prod-plan: ## Plan for production environment (with protections)
	@terraform plan -var="environment=prod" -var="enable_deletion_protection=true" -var="log_retention_days=90"

# Security helpers
security-scan: ## Run basic security validation
	@echo "🔒 Running security checks..."
	@echo "Checking for sensitive data in .tfvars files..."
	@if find . -name "*.tfvars" -not -name "*.example" | xargs grep -l "password\|secret\|key" 2>/dev/null; then \
		echo "⚠️  WARNING: Found potential secrets in .tfvars files!"; \
		echo "Make sure no actual secrets are committed to git."; \
	else \
		echo "✅ No obvious secrets found in .tfvars files"; \
	fi

# Cost estimation (requires infracost)
cost-estimate: ## Estimate infrastructure costs (requires infracost CLI)
	@if command -v infracost >/dev/null 2>&1; then \
		echo "💰 Estimating infrastructure costs..."; \
		infracost breakdown --path .; \
	else \
		echo "❌ infracost CLI not found. Install from: https://www.infracost.io/docs/"; \
		echo "📊 Manual cost estimation:"; \
		echo "  - Fargate tasks: ~$$6-24/month"; \
		echo "  - ALB: ~$$16-18/month"; \
		echo "  - CloudWatch Logs: ~$$1-3/month"; \
		echo "  - ECR Storage: ~$$0.10/GB/month"; \
		echo "  - Total: ~$$23-45/month"; \
	fi

# Backup and restore
backup-state: ## Backup Terraform state file
	@echo "💾 Backing up Terraform state..."
	@mkdir -p backups
	@terraform state pull > backups/terraform-$(shell date +%Y%m%d-%H%M%S).tfstate
	@echo "✅ State backed up to backups/ directory"

# AWS helpers
aws-check: ## Check AWS credentials and permissions
	@echo "🔍 Checking AWS configuration..."
	@aws sts get-caller-identity || (echo "❌ AWS credentials not configured" && exit 1)
	@echo "✅ AWS credentials configured"

# Docker helpers (for container deployment)
docker-build: ## Build Docker image (run from project root)
	@if [ -f ../Dockerfile ]; then \
		cd .. && docker build -t $(shell terraform output -raw ecr_repository_url 2>/dev/null || echo "document-categoriser-app"):latest .; \
	else \
		echo "❌ Dockerfile not found in parent directory"; \
		exit 1; \
	fi

docker-push: docker-build ## Build and push Docker image to ECR
	@ECR_REPO=$$(terraform output -raw ecr_repository_url 2>/dev/null); \
	if [ -n "$$ECR_REPO" ]; then \
		echo "📦 Pushing image to ECR..."; \
		aws ecr get-login-password --region $$(terraform output -raw aws_region) | docker login --username AWS --password-stdin $$ECR_REPO; \
		docker push $$ECR_REPO:latest; \
		echo "✅ Image pushed successfully"; \
	else \
		echo "❌ ECR repository not found. Run 'make apply' first."; \
		exit 1; \
	fi

# Complete deployment workflow
deploy: init plan apply docker-push ## Complete deployment: init -> plan -> apply -> build -> push
	@echo "🎉 Deployment completed!"
	@echo "Application URL: $$(terraform output -raw application_url)"

# Emergency procedures
emergency-scale-down: ## Scale ECS service to 0 (emergency cost saving)
	@echo "🚨 Emergency: Scaling ECS service to 0..."
	@CLUSTER=$$(terraform output -raw ecs_cluster_name 2>/dev/null); \
	SERVICE=$$(terraform output -raw ecs_service_name 2>/dev/null); \
	if [ -n "$$CLUSTER" ] && [ -n "$$SERVICE" ]; then \
		aws ecs update-service --cluster $$CLUSTER --service $$SERVICE --desired-count 0; \
		echo "✅ ECS service scaled to 0"; \
	else \
		echo "❌ Could not find ECS cluster/service"; \
	fi

emergency-scale-up: ## Scale ECS service back to 1 (restore service)
	@echo "🔄 Restoring ECS service to 1 task..."
	@CLUSTER=$$(terraform output -raw ecs_cluster_name 2>/dev/null); \
	SERVICE=$$(terraform output -raw ecs_service_name 2>/dev/null); \
	if [ -n "$$CLUSTER" ] && [ -n "$$SERVICE" ]; then \
		aws ecs update-service --cluster $$CLUSTER --service $$SERVICE --desired-count 1; \
		echo "✅ ECS service scaled to 1"; \
	else \
		echo "❌ Could not find ECS cluster/service"; \
	fi
