# Document Categoriser App - AWS App Runner Configuration
# This file defines the infrastructure using AWS App Runner for cost optimization

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      Repository    = var.repository_url
      Owner         = var.project_owner
    }
  }
}

# Data sources for existing AWS resources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Generate unique resource names to avoid conflicts
locals {
  resource_name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    Repository    = var.repository_url
    Owner         = var.project_owner
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Reference existing ECR Repository (created outside of Terraform)
data "aws_ecr_repository" "app_repository" {
  name = var.ecr_repository_name
}

# IAM Role for App Runner
resource "aws_iam_role" "apprunner_instance_role" {
  name = "document-categoriser-${var.environment}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Role for App Runner ECR Access
resource "aws_iam_role" "apprunner_access_role" {
  name = "document-categoriser-${var.environment}-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy Attachment for ECR Access
resource "aws_iam_role_policy_attachment" "apprunner_access_role_policy" {
  role       = aws_iam_role.apprunner_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# App Runner Auto Scaling Configuration
resource "aws_apprunner_auto_scaling_configuration_version" "app" {
  auto_scaling_configuration_name = "document-categoriser-${var.environment}-as"

  max_concurrency = var.max_concurrency
  max_size        = var.max_size
  min_size        = var.min_size

  tags = local.common_tags
}

# App Runner Service
resource "aws_apprunner_service" "app" {
  service_name = "document-categoriser-${var.environment}"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access_role.arn
    }
    
    image_repository {
      image_configuration {
        port = var.container_port
        
        runtime_environment_variables = {
          for env in var.container_environment_variables : env.name => env.value
        }
        
        runtime_environment_secrets = {
          for secret in var.container_secrets : secret.name => secret.valueFrom
        }
      }
      
      image_identifier      = "${data.aws_ecr_repository.app_repository.repository_url}:${var.image_tag}"
      image_repository_type = "ECR"
    }
    
    auto_deployments_enabled = var.auto_deployments_enabled
  }

  instance_configuration {
    cpu               = var.apprunner_cpu
    memory            = var.apprunner_memory
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.app.arn

  health_check_configuration {
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = "HTTP"
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy_attachment.apprunner_access_role_policy]
}

# Custom Domain Association (if domain is provided)
resource "aws_apprunner_custom_domain_association" "app" {
  count            = var.domain_name != "" ? 1 : 0
  domain_name      = var.domain_name
  service_arn      = aws_apprunner_service.app.arn
  enable_www_subdomain = var.enable_www_subdomain
}

# Route 53 Records for Custom Domain (if domain is provided)
data "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

resource "aws_route53_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_apprunner_custom_domain_association.app[0].dns_target]

  depends_on = [aws_apprunner_custom_domain_association.app]
}

resource "aws_route53_record" "app_www" {
  count   = var.domain_name != "" && var.enable_www_subdomain ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_apprunner_custom_domain_association.app[0].dns_target]

  depends_on = [aws_apprunner_custom_domain_association.app]
}
