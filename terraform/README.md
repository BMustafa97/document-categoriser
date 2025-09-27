# Arabic Recognition App - AWS App Runner Infrastructure

This directory contains the Terraform configuration for deploying the Arabic Recognition App infrastructure on AWS using **AWS App Runner** - a cost-effective, fully managed service that eliminates the need for expensive load balancers and complex ECS configurations.

## 🏗️ Architecture

```
Internet
    |
    └── AWS App Runner Service (with Auto HTTPS)
            |
            ├── Auto Scaling (1-3 instances)
            ├── Load Balancing (Built-in)
            ├── SSL/HTTPS (Automatic)
            └── Container Runtime
                    |
                    └── ECR Repository (Your Application)
```

## 💰 Cost Savings

By switching from ECS + ALB to App Runner, you save approximately **$20-30/month**:

- **ALB Cost**: ~$16-18/month → **ELIMINATED** ✅
- **VPC/NAT Costs**: ~$5-10/month → **ELIMINATED** ✅
- **ECS Management**: Complex → **FULLY MANAGED** ✅
- **SSL Certificates**: Manual ACM setup → **AUTOMATIC** ✅
- **Load Balancing**: Manual ALB config → **BUILT-IN** ✅

**Total Monthly Cost**: ~$3-15/month (vs ~$25-45/month with ECS+ALB)

## 📁 File Structure

```
terraform/
├── main.tf                    # App Runner service and IAM roles
├── variables.tf               # App Runner specific variables
├── outputs.tf                 # Service URLs and configuration info
├── versions.tf                # Provider version constraints
├── locals.tf                  # Local values and validation
├── terraform.tfvars.example   # Example configuration
└── README.md                 # This file
```

## 🚀 Quick Start

### 1. Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- **Existing ECR Repository** with your application image

> **⚠️ Important**: Your ECR repository must exist and contain a Docker image before deployment.

### 2. Configuration

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration
nano terraform.tfvars
```

### 3. Key Configuration Options

```hcl
# Basic Configuration
project_name   = "arabic-recognition-app"
environment    = "prod"
aws_region     = "eu-west-1"

# App Runner Settings
apprunner_cpu    = "0.25 vCPU"  # Start small, scales automatically
apprunner_memory = "0.5 GB"     # Cost-effective for most apps
container_port   = 3000

# Auto Scaling
min_size        = 1    # Minimum instances
max_size        = 3    # Maximum instances
max_concurrency = 100  # Requests per instance

# Custom Domain (Optional)
domain_name = "myapp.example.com"  # Leave empty for App Runner URL
```

### 4. Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply
```

## 🌐 Accessing Your Application

### Option 1: App Runner Default URL (Automatic HTTPS)
After deployment, get your App Runner URL:
```bash
terraform output application_url_default
# Output: https://abc123.eu-west-1.awsapprunner.com
```

### Option 2: Custom Domain (Optional)
If you configured a custom domain:
```bash
terraform output application_url_custom
# Output: https://myapp.example.com
```

## 🔄 Auto Deployments

App Runner can automatically deploy when you push new images:

```bash
# Push a new image to ECR
docker push your-account.dkr.ecr.eu-west-1.amazonaws.com/arabic-recognition-app:latest

# App Runner automatically detects and deploys (if auto_deployments_enabled = true)
```

## 📊 Monitoring

### App Runner Console
- View metrics in AWS Console: App Runner → Services → your-service
- Built-in metrics: Requests, Response Time, CPU, Memory
- Automatic logging to CloudWatch

### Terraform Outputs
```bash
# Get service information
terraform output apprunner_service_url
terraform output apprunner_service_status
terraform output estimated_monthly_cost
```

## 🔧 Configuration Reference

### App Runner Instance Sizes

| CPU     | Memory Options |
|---------|---------------|
| 0.25 vCPU | 0.5 GB, 1 GB |
| 0.5 vCPU  | 1 GB, 2 GB |
| 1 vCPU    | 2 GB, 3 GB, 4 GB |
| 2 vCPU    | 4 GB, 6 GB, 8 GB |
| 4 vCPU    | 8 GB, 10 GB, 12 GB |

### Health Check Settings
```hcl
health_check_path                = "/"      # Your health endpoint
health_check_healthy_threshold   = 1        # Success count
health_check_unhealthy_threshold = 5        # Failure count
health_check_interval           = 10       # Check frequency (seconds)
health_check_timeout            = 2        # Timeout (seconds)
```

## 🔒 Security Features

- **Automatic HTTPS**: SSL certificates managed automatically
- **IAM Integration**: Secure ECR access with minimal permissions
- **VPC-less**: No complex networking configuration required
- **DDoS Protection**: Built-in AWS protection
- **Auto Updates**: Platform updates handled by AWS

## 💡 Best Practices

### Cost Optimization
- Start with small instance sizes (0.25 vCPU, 0.5 GB)
- Use auto-scaling to handle traffic spikes
- Monitor usage and adjust instance sizes

### Performance
- Optimize your Docker image size
- Implement proper health checks
- Use appropriate concurrency settings

### Security
- Use IAM roles instead of access keys
- Store secrets in AWS Secrets Manager
- Enable CloudTrail for audit logging

## 🔄 Updating Your Application

### Manual Deployment
```bash
# Build and push new image
docker build -t your-app .
docker tag your-app your-account.dkr.ecr.region.amazonaws.com/repo:new-tag
docker push your-account.dkr.ecr.region.amazonaws.com/repo:new-tag

# Update Terraform with new tag
terraform apply -var="image_tag=new-tag"
```

### Automatic Deployment (Recommended)
Set `auto_deployments_enabled = true` in your configuration. App Runner will automatically deploy when you push new images to ECR.

## 📝 Troubleshooting

### Common Issues

**Service Failed to Start**
- Check your application listens on the correct port
- Verify environment variables are correct
- Review App Runner service logs in CloudWatch

**Custom Domain Not Working**
- Ensure DNS points to the App Runner DNS target
- Check domain validation status
- Verify Route 53 hosted zone exists

**High Costs**
- Check if you're using appropriate instance sizes
- Monitor request patterns and adjust concurrency
- Consider using auto-scaling more aggressively

### Useful Commands
```bash
# Check service status
aws apprunner describe-service --service-arn $(terraform output -raw apprunner_service_arn)

# View recent logs
aws logs describe-log-groups --log-group-name-prefix /aws/apprunner

# Force new deployment
aws apprunner start-deployment --service-arn $(terraform output -raw apprunner_service_arn)
```

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

> **Note**: This will delete your App Runner service but preserve your ECR repository and images.

## 📚 Additional Resources

- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [App Runner Pricing](https://aws.amazon.com/apprunner/pricing/)
- [Terraform AWS Provider - App Runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service)

## 🤝 Support

If you encounter issues:
1. Check the [troubleshooting section](#-troubleshooting)
2. Review AWS App Runner service logs
3. Validate your Terraform configuration
4. Ensure your ECR repository and images exist