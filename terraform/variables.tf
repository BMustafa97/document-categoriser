# Variables for Document Categoriser App Infrastructure

# General Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "document-categoriser"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project_owner" {
  description = "Owner of the project (email or username)"
  type        = string
  default     = ""
}

variable "repository_url" {
  description = "URL of the source code repository"
  type        = string
  default     = ""
}

# ECR Configuration
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "document-categoriser"
}

# Domain and SSL Configuration
variable "domain_name" {
  description = "Domain name for HTTPS certificate (leave empty for HTTP only)"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional domain names for the SSL certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID (leave empty to create new zone)"
  type        = string
  default     = ""
}

# ECS Configuration
variable "task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, etc.)"
  type        = number
  default     = 256
  
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory for the ECS task in MB"
  type        = number
  default     = 512
  
  validation {
    condition = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory must be between 512 and 30720 MB."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
  
  validation {
    condition     = var.desired_count >= 1 && var.desired_count <= 10
    error_message = "Desired count must be between 1 and 10."
  }
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "document-categoriser"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 5001
  
  validation {
    condition     = var.container_port > 0 && var.container_port < 65536
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "health_check_path" {
  description = "Health check path for the load balancer"
  type        = string
  default     = "/"
}

variable "health_check_command" {
  description = "Health check command for the container"
  type        = string
  default     = "curl -f http://localhost:5001/health || exit 1"
}

# Auto Scaling Configuration
variable "enable_autoscaling" {
  description = "Enable auto scaling for ECS service"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 3
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70.0
  
  validation {
    condition     = var.cpu_target_value > 0 && var.cpu_target_value <= 100
    error_message = "CPU target value must be between 0 and 100."
  }
}

# Load Balancer Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket for ALB access logs (leave empty to disable)"
  type        = string
  default     = ""
}

# CloudWatch Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention value."
  }
}

# Security Configuration
variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging (disable in production)"
  type        = bool
  default     = false
}

# Container Configuration
variable "container_environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "FLASK_ENV"
      value = "production"
    },
    {
      name  = "FLASK_APP"
      value = "app.py"
    }
  ]
}

variable "container_secrets" {
  description = "Secrets for the container (from AWS Secrets Manager or Parameter Store)"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

# Advanced Networking (optional)
variable "vpc_id" {
  description = "VPC ID to use (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs to use (leave empty to use default subnets)"
  type        = list(string)
  default     = []
}

# Cost Optimization
variable "use_fargate_spot" {
  description = "Use Fargate Spot for cost optimization (may cause interruptions)"
  type        = bool
  default     = false
}
