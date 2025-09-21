# Arabic Recognition App - Terraform Infrastructure

This directory contains the complete Infrastructure as Code (IaC) for deploying the Arabic Recognition App on AWS using Terraform.

## 🏗️ Architecture

```
Internet
    |
    └── Application Load Balancer (ALB)
            |
            └── Target Group
                    |
                    └── ECS Fargate Service
                            |
                            └── Container Tasks
                                    |
                                    └── ECR Repository (External)
```

## 📁 File Structure

```
terraform/
├── main.tf                    # Main infrastructure resources
├── variables.tf               # Input variables and validation
├── outputs.tf                 # Output values and information
├── versions.tf                # Provider version constraints
├── locals.tf                  # Local values and computed variables
├── Makefile                   # Helper commands for common operations
├── terraform.tfvars.example   # Example configuration file
├── .gitignore                # Git ignore rules (protects secrets)
└── README.md                 # This file
```

## 🚀 Quick Start

### 1. Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- Docker (for building and pushing images)
- **Existing ECR Repository** - The repository must exist before deployment

> **⚠️ Important**: Ensure your ECR repository exists. The Terraform configuration references it as a data source but doesn't create it.

### 2. Initial Setup

```bash
# Clone the repository
git clone https://github.com/BMustafa97/learn-99-names.git
cd learn-99-names/terraform

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Initialize Terraform
make init

# Validate configuration
make check
```

### 3. Deploy Infrastructure

```bash
# Plan the deployment
make plan

# Apply the infrastructure
make apply

# Complete deployment with Docker image
make deploy
```

## ⚙️ Configuration

### Basic Configuration (terraform.tfvars)

```hcl
# Required settings
aws_region     = "eu-west-1"
environment    = "dev"
project_name   = "arabic-recognition-app"
project_owner  = "your-email@example.com"

# Optional: Enable HTTPS
domain_name = "myapp.example.com"

# Container settings
container_port = 3000
desired_count  = 1
task_cpu      = 256
task_memory   = 512
```

### Environment-Specific Configurations

#### Development
```hcl
environment = "dev"
enable_deletion_protection = false
log_retention_days = 7
enable_autoscaling = false
```

#### Production
```hcl
environment = "prod"
enable_deletion_protection = true
log_retention_days = 90
enable_autoscaling = true
max_capacity = 5
alb_access_logs_bucket = "your-production-logs-bucket"
```

## 🔒 Security Features

### Built-in Security

- **Encryption at Rest**: ECR images, CloudWatch logs (KMS)
- **Encryption in Transit**: HTTPS/TLS for web traffic
- **Network Security**: Security groups with least privilege
- **IAM Security**: Minimal required permissions
- **Container Security**: Non-root containers, readonly filesystem options

### Secrets Management

Never commit secrets to git! Use AWS services:

```bash
# Create secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "prod/arabic-recognition-app/api-key" \
  --secret-string "your-secret-value"

# Reference in terraform.tfvars
container_secrets = [
  {
    name      = "API_KEY"
    valueFrom = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:prod/arabic-recognition-app/api-key"
  }
]
```

## 🛠️ Available Commands

The Makefile provides convenient commands:

```bash
make help           # Show all available commands
make init           # Initialize Terraform
make plan           # Plan infrastructure changes
make apply          # Apply changes
make destroy        # Destroy infrastructure
make status         # Show current status
make outputs        # Show infrastructure outputs

# Development workflow
make dev-plan       # Plan for development
make deploy         # Complete deployment workflow

# Maintenance
make format         # Format Terraform files
make validate       # Validate configuration
make upgrade        # Upgrade providers
make backup-state   # Backup state file

# Emergency operations
make emergency-scale-down  # Scale to 0 (cost saving)
make emergency-scale-up    # Scale back to 1

# Docker operations
make docker-build   # Build container image
make docker-push    # Push to ECR
```

## 💰 Cost Management

### Estimated Monthly Costs

| Component | Development | Production | Notes |
|-----------|-------------|------------|-------|
| ECS Fargate | $6-12 | $12-60 | Based on task size/count |
| ALB | $16-18 | $16-18 | Fixed cost |
| CloudWatch Logs | $1-3 | $3-10 | Based on volume |
| ECR Storage | $0.10/GB | $1-5 | Based on images |
| **Total** | **$23-33** | **$32-93** | Typical ranges |

### Cost Optimization

1. **Development**: Use Fargate Spot
   ```hcl
   use_fargate_spot = true
   ```

2. **Auto Scaling**: Scale to zero when not used
   ```hcl
   enable_autoscaling = true
   min_capacity = 0
   ```

3. **Log Retention**: Reduce for non-production
   ```hcl
   log_retention_days = 7
   ```

## 📊 Monitoring

### Built-in Monitoring

- **ECS Container Insights**: Enabled by default
- **ALB Metrics**: Request count, latency, error rates
- **CloudWatch Logs**: Centralized application logs
- **Health Checks**: ALB and container health monitoring

### Viewing Logs

```bash
# View application logs
aws logs tail /ecs/arabic-recognition-app --follow

# View specific time range
aws logs filter-log-events \
  --log-group-name "/ecs/arabic-recognition-app" \
  --start-time 1609459200000
```

## 🔄 CI/CD Integration

### GitHub Actions

Use the infrastructure outputs in your CI/CD pipeline:

```yaml
- name: Deploy to ECS
  env:
    ECR_REPOSITORY: ${{ steps.terraform.outputs.ecr_repository_url }}
    ECS_CLUSTER: ${{ steps.terraform.outputs.ecs_cluster_name }}
    ECS_SERVICE: ${{ steps.terraform.outputs.ecs_service_name }}
```

### Infrastructure Updates

```bash
# Update infrastructure
git pull origin main
terraform plan
terraform apply

# Update application
make docker-push

# Update ECS service (triggers deployment)
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

## 🧪 Testing

### Validate Infrastructure

```bash
# Test configuration
make validate

# Test plan
make plan

# Test specific environment
terraform plan -var="environment=staging"
```

### Health Checks

```bash
# Check application health
curl -I $(terraform output -raw application_url)

# Check ECS service health
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name)

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)
```

## 🐛 Troubleshooting

### Common Issues

1. **SSL Certificate Validation**
   ```bash
   # Get DNS records to add
   terraform output ssl_certificate_validation_records
   ```

2. **ECS Tasks Not Starting**
   ```bash
   # Check service events
   aws ecs describe-services --cluster CLUSTER --services SERVICE
   
   # Check container logs
   aws logs tail /ecs/arabic-recognition-app --follow
   ```

3. **Load Balancer Health Checks Failing**
   ```bash
   # Test direct container access
   curl -I http://$(terraform output -raw load_balancer_dns_name)
   
   # Check target group health
   aws elbv2 describe-target-health --target-group-arn TG_ARN
   ```

### Debug Mode

```bash
# Enable Terraform debugging
export TF_LOG=DEBUG
terraform plan

# Enable AWS CLI debugging
aws ecs describe-clusters --debug
```

## 📚 Additional Resources

- **Main Documentation**: See [terraform-inf.md](../terraform-inf.md) for comprehensive guide
- **Infrastructure Scripts**: Original bash scripts in `scripts/` directory
- **Terraform Documentation**: [terraform.io](https://terraform.io)
- **AWS ECS Guide**: [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)

## 🤝 Contributing

1. **Test Changes**: Always test in development environment first
2. **Security First**: Never commit secrets or state files
3. **Documentation**: Update documentation with changes
4. **Validation**: Run `make check` before committing

## 📞 Support

For issues or questions:

1. Check the troubleshooting section above
2. Review CloudWatch logs and AWS console
3. Consult the main terraform-inf.md documentation
4. Open an issue in the repository

---

**Security Reminder**: This infrastructure is designed for public repositories. Never commit `.tfvars` files, state files, or any secrets to version control!
