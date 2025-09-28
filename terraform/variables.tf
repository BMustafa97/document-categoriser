# Variables for Document Categoriser App Infrastructure - AWS App Runner

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

# Domain Configuration
variable "domain_name" {
  description = "Domain name for custom domain (leave empty to use App Runner default URL)"
  type        = string
  default     = ""
}

variable "enable_www_subdomain" {
  description = "Enable www subdomain for custom domain"
  type        = bool
  default     = true
}

# App Runner Configuration
variable "apprunner_cpu" {
  description = "CPU units for App Runner (0.25 vCPU, 0.5 vCPU, 1 vCPU, 2 vCPU, 4 vCPU)"
  type        = string
  default     = "0.25 vCPU"
  
  validation {
    condition     = contains(["0.25 vCPU", "0.5 vCPU", "1 vCPU", "2 vCPU", "4 vCPU"], var.apprunner_cpu)
    error_message = "App Runner CPU must be one of: 0.25 vCPU, 0.5 vCPU, 1 vCPU, 2 vCPU, 4 vCPU."
  }
}

variable "apprunner_memory" {
  description = "Memory for App Runner (0.5 GB, 1 GB, 2 GB, 3 GB, 4 GB, 6 GB, 8 GB, 10 GB, 12 GB)"
  type        = string
  default     = "0.5 GB"
  
  validation {
    condition     = contains(["0.5 GB", "1 GB", "2 GB", "3 GB", "4 GB", "6 GB", "8 GB", "10 GB", "12 GB"], var.apprunner_memory)
    error_message = "App Runner memory must be a valid value."
  }
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

variable "auto_deployments_enabled" {
  description = "Enable automatic deployments when new image is pushed to ECR"
  type        = bool
  default     = true
}

# Auto Scaling Configuration
variable "max_concurrency" {
  description = "Maximum number of concurrent requests per instance"
  type        = number
  default     = 100
  
  validation {
    condition     = var.max_concurrency >= 1 && var.max_concurrency <= 1000
    error_message = "Max concurrency must be between 1 and 1000."
  }
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_size >= 1 && var.min_size <= 25
    error_message = "Min size must be between 1 and 25."
  }
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
  
  validation {
    condition     = var.max_size >= 1 && var.max_size <= 25
    error_message = "Max size must be between 1 and 25."
  }
}

# Health Check Configuration
variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 1
  
  validation {
    condition     = var.health_check_healthy_threshold >= 1 && var.health_check_healthy_threshold <= 20
    error_message = "Health check healthy threshold must be between 1 and 20."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 5
  
  validation {
    condition     = var.health_check_unhealthy_threshold >= 1 && var.health_check_unhealthy_threshold <= 20
    error_message = "Health check unhealthy threshold must be between 1 and 20."
  }
}

variable "health_check_interval" {
  description = "Time interval between health checks (in seconds)"
  type        = number
  default     = 10
  
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 20
    error_message = "Health check interval must be between 5 and 20 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout (in seconds)"
  type        = number
  default     = 2
  
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 20
    error_message = "Health check timeout must be between 2 and 20 seconds."
  }
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
      name  = "PYTHONUNBUFFERED"
      value = "1"
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
