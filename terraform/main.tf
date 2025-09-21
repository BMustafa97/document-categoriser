# Document Categoriser App - Main Terraform Configuration
# This file defines the core infrastructure for the Document Categoriser App

  # Backend configuration should be uncommented and configured for production
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "document-categoriser/terraform.tfstate"
  #   region         = "eu-west-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }

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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Generate unique resource names to avoid conflicts
locals {
  resource_name_prefix = "${var.project_name}-${var.environment}"
}

# ==========================================
# S3 Buckets for Document Processing
# ==========================================

# S3 bucket for uploaded documents
resource "aws_s3_bucket" "documents" {
  bucket = "${local.resource_name_prefix}-documents-${random_string.bucket_suffix.result}"

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-documents-bucket"
  })
}

# S3 bucket for processed documents/results
resource "aws_s3_bucket" "processed_documents" {
  bucket = "${local.resource_name_prefix}-processed-${random_string.bucket_suffix.result}"

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-processed-bucket"
  })
}

# Random string for bucket uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket versioning for documents
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "processed_documents" {
  bucket = aws_s3_bucket.processed_documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_documents" {
  bucket = aws_s3_bucket.processed_documents.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "processed_documents" {
  bucket = aws_s3_bucket.processed_documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS Key for S3 encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for ${var.project_name} S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-s3-kms-key"
  })
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/${local.resource_name_prefix}-s3"
  target_key_id = aws_kms_key.s3_key.key_id
}

# ==========================================
# SQS Queue for Document Processing
# ==========================================

# SQS queue for document processing jobs
resource "aws_sqs_queue" "document_processing" {
  name                       = "${local.resource_name_prefix}-processing-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600 # 14 days
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.document_processing_dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-processing-queue"
  })
}

# Dead Letter Queue
resource "aws_sqs_queue" "document_processing_dlq" {
  name                      = "${local.resource_name_prefix}-processing-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-processing-dlq"
  })
}

# Reference existing ECR Repository (created outside of Terraform)
data "aws_ecr_repository" "app_repository" {
  name = var.ecr_repository_name
}

# ==========================================
# IAM Roles for Document Processing
# ==========================================

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_processing_role" {
  name = "${local.resource_name_prefix}-lambda-processing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-lambda-processing-role"
  })
}

# Lambda processing policy
resource "aws_iam_role_policy" "lambda_processing_policy" {
  name = "${local.resource_name_prefix}-lambda-processing-policy"
  role = aws_iam_role.lambda_processing_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.documents.arn}/*",
          "${aws_s3_bucket.processed_documents.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "textract:DetectDocumentText",
          "textract:AnalyzeDocument",
          "textract:StartDocumentAnalysis",
          "textract:GetDocumentAnalysis",
          "textract:StartDocumentTextDetection",
          "textract:GetDocumentTextDetection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "comprehend:DetectDominantLanguage",
          "comprehend:DetectEntities",
          "comprehend:DetectKeyPhrases",
          "comprehend:DetectPiiEntities",
          "comprehend:DetectSentiment",
          "comprehend:DetectSyntax",
          "comprehend:ClassifyDocument"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = [
          aws_sqs_queue.document_processing.arn,
          aws_sqs_queue.document_processing_dlq.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.s3_key.arn,
          aws_kms_key.logs_key.arn
        ]
      }
    ]
  })
}

# ==========================================
# Lambda Functions for Document Processing
# ==========================================

# Lambda function for document processing
resource "aws_lambda_function" "document_processor" {
  filename         = "document_processor.zip"
  function_name    = "${local.resource_name_prefix}-document-processor"
  role            = aws_iam_role.lambda_processing_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      DOCUMENTS_BUCKET           = aws_s3_bucket.documents.bucket
      PROCESSED_DOCUMENTS_BUCKET = aws_s3_bucket.processed_documents.bucket
      SQS_QUEUE_URL             = aws_sqs_queue.document_processing.url
      AWS_DEFAULT_REGION         = data.aws_region.current.name
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-document-processor"
  })

  # Create a placeholder zip file
  depends_on = [null_resource.lambda_zip]
}

# Create placeholder Lambda zip file
resource "null_resource" "lambda_zip" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p /tmp/lambda_function
      cat << 'EOF' > /tmp/lambda_function/lambda_function.py
import json
import boto3
import os

def lambda_handler(event, context):
    print("Document processing Lambda triggered")
    print(json.dumps(event))
    
    # This is a placeholder - implement actual document processing logic
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Document processing placeholder',
            'event': event
        })
    }
EOF
      cd /tmp/lambda_function && zip -r ${path.module}/document_processor.zip .
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Lambda event source mapping for SQS
resource "aws_lambda_event_source_mapping" "document_processor_sqs" {
  event_source_arn = aws_sqs_queue.document_processing.arn
  function_name    = aws_lambda_function.document_processor.arn
  batch_size       = 10
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs_key.arn

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-logs"
  })
}

# KMS Key for log encryption
resource "aws_kms_key" "logs_key" {
  description             = "KMS key for ${var.project_name} log encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-logs-kms-key"
  })
}

resource "aws_kms_alias" "logs_key_alias" {
  name          = "alias/${local.resource_name_prefix}-logs"
  target_key_id = aws_kms_key.logs_key.key_id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name_prefix = "${local.resource_name_prefix}-alb-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for ${var.project_name} Application Load Balancer"

  # HTTPS traffic from internet
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP traffic from internet (for redirect to HTTPS)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "ecs_sg" {
  name_prefix = "${local.resource_name_prefix}-ecs-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for ${var.project_name} ECS tasks"

  # Allow traffic from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # All outbound traffic (required for pulling images, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-ecs-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${local.resource_name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = var.alb_access_logs_bucket
    enabled = var.alb_access_logs_bucket != "" ? true : false
    prefix  = "${var.project_name}-alb"
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${local.resource_name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  # Enable connection draining
  deregistration_delay = 30

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-tg"
  })
}

# SSL Certificate (if domain is provided)
resource "aws_acm_certificate" "main" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-ssl-certificate"
  })
}

# ==========================================
# Route 53 DNS Configuration (HTTPS Setup)
# ==========================================
# This section creates:
# 1. Hosted Zone - Manages DNS for your domain
# 2. Certificate Validation Records - Auto-validates SSL certificate
# 3. Certificate Validation Waiter - Waits for certificate to be validated
# 4. A Record - Points your domain to the ALB
#
# IMPORTANT: After deployment, configure your domain registrar to use
# the name servers from the 'route53_name_servers' output (if creating new zone).

# Route 53 Hosted Zone - Use existing or create new
resource "aws_route53_zone" "main" {
  count = var.domain_name != "" && var.route53_zone_id == "" ? 1 : 0
  name  = var.domain_name

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-hosted-zone"
  })
}

# Reference existing Route 53 hosted zone (if provided)
data "aws_route53_zone" "existing" {
  count   = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
}

# Local values to determine which zone to use
locals {
  route53_zone_id = var.domain_name != "" ? (
    var.route53_zone_id != "" ? data.aws_route53_zone.existing[0].zone_id : aws_route53_zone.main[0].zone_id
  ) : null
}

# Certificate validation DNS records
resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

# Certificate validation waiter
resource "aws_acm_certificate_validation" "main" {
  count           = var.domain_name != "" ? 1 : 0
  certificate_arn = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# A record pointing domain to ALB
resource "aws_route53_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# HTTPS Listener (if SSL certificate exists)
resource "aws_lb_listener" "https" {
  count             = var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.main[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  depends_on = [aws_acm_certificate_validation.main]
}

# HTTP Listener (redirect to HTTPS if certificate exists, otherwise forward)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.domain_name != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.domain_name != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.domain_name == "" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.app.arn
        }
      }
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.resource_name_prefix}-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.app_logs.name
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-cluster"
  })
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# IAM Roles for ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.resource_name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_role_additional" {
  name = "${local.resource_name_prefix}-ecs-task-execution-additional"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.logs_key.arn
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.resource_name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-ecs-task-role"
  })
}

# ECS Task role policy for document processing
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${local.resource_name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.documents.arn}/*",
          "${aws_s3_bucket.processed_documents.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.documents.arn,
          aws_s3_bucket.processed_documents.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          aws_sqs_queue.document_processing.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.s3_key.arn
        ]
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${local.resource_name_prefix}-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.task_cpu
  memory                  = var.task_memory

  container_definitions = jsonencode([
    {
      name  = var.container_name
      image = "${data.aws_ecr_repository.app_repository.repository_url}:${var.image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = concat(var.container_environment_variables, [
        {
          name  = "DOCUMENTS_BUCKET"
          value = aws_s3_bucket.documents.bucket
        },
        {
          name  = "PROCESSED_DOCUMENTS_BUCKET" 
          value = aws_s3_bucket.processed_documents.bucket
        },
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.document_processing.url
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = data.aws_region.current.name
        }
      ])

      secrets = var.container_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", var.health_check_command]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-task-definition"
  })
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${local.resource_name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count

  platform_version = "LATEST"

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 100
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets         = data.aws_subnets.default.ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Enable execute command for debugging (optional)
  enable_execute_command = var.enable_execute_command

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role.ecs_task_execution_role,
  ]

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-service"
  })
}

# Auto Scaling for ECS Service
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${local.resource_name_prefix}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
