#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 AWS App Runner Deployment Script${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    echo -e "${RED}❌ Please run this script from the terraform directory${NC}"
    exit 1
fi

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
echo ""

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install Terraform first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Terraform found: $(terraform version -json | jq -r '.terraform_version')${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS CLI found${NC}"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS credentials configured${NC}"

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo -e "${BLUE}📍 Account: ${AWS_ACCOUNT}, Region: ${AWS_REGION}${NC}"

echo ""

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}📝 Creating terraform.tfvars from example...${NC}"
    
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${GREEN}✅ Created terraform.tfvars${NC}"
        echo -e "${YELLOW}⚠️  Please edit terraform.tfvars with your configuration before continuing${NC}"
        echo ""
        read -p "$(echo -e ${YELLOW}Do you want to edit terraform.tfvars now? [y/N]: ${NC})" edit_config
        if [[ $edit_config =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} terraform.tfvars
        fi
    else
        echo -e "${RED}❌ terraform.tfvars.example not found${NC}"
        exit 1
    fi
fi

# Validate required variables
echo -e "${YELLOW}🔍 Validating configuration...${NC}"
echo ""

# Check ECR repository exists
ECR_REPO=$(grep 'ecr_repository_name' terraform.tfvars | cut -d'"' -f2 | cut -d'"' -f1 | sed 's/.*= *"//' | sed 's/".*//')
if [ -n "$ECR_REPO" ]; then
    if aws ecr describe-repositories --repository-names "$ECR_REPO" &> /dev/null; then
        echo -e "${GREEN}✅ ECR repository '$ECR_REPO' exists${NC}"
        
        # Check if images exist
        IMAGE_COUNT=$(aws ecr describe-images --repository-name "$ECR_REPO" --query 'length(imageDetails)' --output text 2>/dev/null || echo "0")
        if [ "$IMAGE_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✅ ECR repository has $IMAGE_COUNT image(s)${NC}"
        else
            echo -e "${YELLOW}⚠️  ECR repository exists but has no images${NC}"
            echo -e "${YELLOW}   Make sure to push your application image before deployment${NC}"
        fi
    else
        echo -e "${RED}❌ ECR repository '$ECR_REPO' not found${NC}"
        echo -e "${YELLOW}💡 Create it with: aws ecr create-repository --repository-name $ECR_REPO${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}🏗️  Deployment Plan${NC}"
echo -e "${BLUE}=================${NC}"
echo ""
echo -e "• AWS App Runner Service (fully managed)"
echo -e "• Automatic HTTPS with managed SSL certificates"
echo -e "• Auto-scaling based on traffic (pay-per-use)"
echo -e "• Built-in load balancing (no ALB needed)"
echo -e "• Estimated cost: ~$3-15/month (vs ~$25-45 with ECS+ALB)"
echo ""

read -p "$(echo -e ${YELLOW}Do you want to proceed with the deployment? [y/N]: ${NC})" confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔄 Initializing Terraform...${NC}"
terraform init

echo ""
echo -e "${BLUE}📋 Creating deployment plan...${NC}"
terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}📝 Review the plan above. This will create:${NC}"
echo -e "• App Runner service"
echo -e "• IAM roles for ECR access"
echo -e "• Auto-scaling configuration"
echo -e "• Custom domain association (if configured)"
echo ""

read -p "$(echo -e ${YELLOW}Apply this plan? [y/N]: ${NC})" apply_confirm
if [[ ! $apply_confirm =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deployment cancelled${NC}"
    rm -f tfplan
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Deploying infrastructure...${NC}"
terraform apply tfplan

echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""

# Get outputs
APP_URL=$(terraform output -raw application_url_default 2>/dev/null || echo "")
CUSTOM_URL=$(terraform output -raw application_url_custom 2>/dev/null || echo "null")
SERVICE_STATUS=$(terraform output -raw apprunner_service_status 2>/dev/null || echo "")

echo -e "${BLUE}🌐 Application URLs:${NC}"
if [ -n "$APP_URL" ]; then
    echo -e "${GREEN}📱 App Runner URL: $APP_URL${NC}"
fi
if [ "$CUSTOM_URL" != "null" ] && [ "$CUSTOM_URL" != "" ]; then
    echo -e "${GREEN}🏷️  Custom Domain: $CUSTOM_URL${NC}"
fi

echo ""
echo -e "${BLUE}📊 Service Status: $SERVICE_STATUS${NC}"
echo ""

if [ "$SERVICE_STATUS" = "RUNNING" ]; then
    echo -e "${GREEN}🎉 Your application is now live!${NC}"
else
    echo -e "${YELLOW}⏳ Service is starting up. This may take a few minutes.${NC}"
    echo -e "${YELLOW}💡 Check status with: terraform output apprunner_service_status${NC}"
fi

echo ""
echo -e "${BLUE}💡 Useful Commands:${NC}"
echo -e "• View service status: ${YELLOW}terraform output apprunner_service_status${NC}"
echo -e "• Get application URL: ${YELLOW}terraform output application_url_default${NC}"
echo -e "• View cost estimate: ${YELLOW}terraform output estimated_monthly_cost${NC}"
echo -e "• Force new deployment: ${YELLOW}aws apprunner start-deployment --service-arn \$(terraform output -raw apprunner_service_arn)${NC}"
echo ""

echo -e "${GREEN}🎊 Deployment completed successfully!${NC}"
echo -e "${GREEN}🎯 Massive cost savings achieved - no more expensive ALB!${NC}"

# Clean up
rm -f tfplan