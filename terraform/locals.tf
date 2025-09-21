# Local Values and Computed Variables
# This file contains computed values and local variables used throughout the configuration

locals {
  # Resource naming
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    Owner         = var.project_owner
    Repository    = var.repository_url
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }

  # Network configuration
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default.ids

  # SSL configuration
  enable_https = var.domain_name != ""
  
  # Container configuration - updated for Flask app
  container_environment_additions = [
    {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }
  ]

  # Capacity provider strategy
  capacity_provider_strategy = var.use_fargate_spot ? [
    {
      capacity_provider = "FARGATE_SPOT"
      weight           = 100
      base             = 0
    }
  ] : [
    {
      capacity_provider = "FARGATE"
      weight           = 100
      base             = 1
    }
  ]

  # Auto scaling configuration
  autoscaling_enabled = var.enable_autoscaling && var.max_capacity > var.min_capacity

  # Security group rules
  alb_ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]

  ecs_ingress_rules = [
    {
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.alb_sg.id
      description              = "HTTP from ALB"
    }
  ]

  # Cost optimization settings
  deployment_configuration = {
    maximum_percent         = var.environment == "prod" ? 200 : 100
    minimum_healthy_percent = var.environment == "prod" ? 100 : 50
  }

  # Monitoring configuration
  enable_container_insights = var.environment != "dev"
  
  # Load balancer configuration
  alb_access_logs_enabled = var.alb_access_logs_bucket != ""
  
  # Certificate configuration
  certificate_validation_timeout = "10m"
  
  # Task definition compatibility
  fargate_compatible_cpu_memory = {
    256  = [512, 1024, 2048]
    512  = [1024, 2048, 3072, 4096]
    1024 = [2048, 3072, 4096, 5120, 6144, 7168, 8192]
    2048 = [4096, 5120, 6144, 7168, 8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384]
    4096 = [8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384, 17408, 18432, 19456, 20480, 21504, 22528, 23552, 24576, 25600, 26624, 27648, 28672, 29696, 30720]
  }
}

# Validation for CPU/Memory combinations
resource "null_resource" "validate_cpu_memory" {
  count = contains(local.fargate_compatible_cpu_memory[var.task_cpu], var.task_memory) ? 0 : 1
  
  lifecycle {
    precondition {
      condition = contains(local.fargate_compatible_cpu_memory[var.task_cpu], var.task_memory)
      error_message = "The specified memory (${var.task_memory}MB) is not compatible with the specified CPU (${var.task_cpu} units). Check AWS Fargate task size documentation for valid combinations."
    }
  }
}
