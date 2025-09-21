# Outputs for Document Categoriser App Infrastructure

# S3 Bucket Outputs
output "documents_bucket_name" {
  description = "Name of the S3 bucket for document uploads"
  value       = aws_s3_bucket.documents.bucket
}

output "documents_bucket_arn" {
  description = "ARN of the S3 bucket for document uploads"
  value       = aws_s3_bucket.documents.arn
}

output "processed_documents_bucket_name" {
  description = "Name of the S3 bucket for processed documents"
  value       = aws_s3_bucket.processed_documents.bucket
}

output "processed_documents_bucket_arn" {
  description = "ARN of the S3 bucket for processed documents"
  value       = aws_s3_bucket.processed_documents.arn
}

# SQS Queue Outputs
output "document_processing_queue_url" {
  description = "URL of the SQS queue for document processing"
  value       = aws_sqs_queue.document_processing.url
}

output "document_processing_queue_arn" {
  description = "ARN of the SQS queue for document processing"
  value       = aws_sqs_queue.document_processing.arn
}

# Lambda Function Outputs
output "document_processor_function_name" {
  description = "Name of the Lambda function for document processing"
  value       = aws_lambda_function.document_processor.function_name
}

output "document_processor_function_arn" {
  description = "ARN of the Lambda function for document processing"
  value       = aws_lambda_function.document_processor.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = data.aws_ecr_repository.app_repository.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = data.aws_ecr_repository.app_repository.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.app.id
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "load_balancer_hosted_zone_id" {
  description = "Hosted zone ID of the load balancer (for Route53 alias records)"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate (if domain is provided)"
  value       = var.domain_name != "" ? aws_acm_certificate.main[0].arn : null
}

output "ssl_certificate_validation_records" {
  description = "DNS records needed for SSL certificate validation (auto-managed by Route 53)"
  value = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
}

# Route 53 Outputs
output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value = var.domain_name != "" ? (
    var.route53_zone_id != "" ? data.aws_route53_zone.existing[0].zone_id : aws_route53_zone.main[0].zone_id
  ) : null
}

output "route53_name_servers" {
  description = "Route 53 name servers (only available for new zones created by Terraform)"
  value       = var.domain_name != "" && var.route53_zone_id == "" ? aws_route53_zone.main[0].name_servers : []
}

output "route53_zone_arn" {
  description = "Route 53 hosted zone ARN"
  value = var.domain_name != "" ? (
    var.route53_zone_id != "" ? data.aws_route53_zone.existing[0].arn : aws_route53_zone.main[0].arn
  ) : null
}

output "using_existing_hosted_zone" {
  description = "Whether using an existing hosted zone or created a new one"
  value       = var.domain_name != "" && var.route53_zone_id != ""
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "security_group_ecs_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs_sg.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.arn
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# Application URLs
output "application_url" {
  description = "URL to access the application"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_lb.main.dns_name}"
}

output "application_url_http" {
  description = "HTTP URL (will redirect to HTTPS if SSL is enabled)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "application_url_https" {
  description = "HTTPS URL (only available if domain is configured)"
  value       = var.domain_name != "" ? "https://${aws_lb.main.dns_name}" : null
}

# Infrastructure Info
output "vpc_id" {
  description = "VPC ID being used"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "Subnet IDs being used"
  value       = data.aws_subnets.default.ids
}

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
  sensitive   = true
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (USD)"
  value = {
    fargate_tasks     = "Fargate: ~$6-24/month (${var.desired_count} tasks, ${var.task_cpu} CPU, ${var.task_memory}MB)"
    load_balancer     = "ALB: ~$16-18/month"
    cloudwatch_logs   = "CloudWatch Logs: ~$1-3/month"
    ecr_storage       = "ECR Storage: ~$0.10 per GB/month"
    s3_storage        = "S3 Storage: ~$0.02-0.05 per GB/month"
    lambda_requests   = "Lambda: ~$0.20 per 1M requests + compute time"
    sqs_requests      = "SQS: ~$0.40-0.76 per 1M requests"
    textract_pages    = "Textract: ~$1.50 per 1000 pages"
    comprehend_units  = "Comprehend: ~$0.0001 per unit"
    data_transfer     = "Data Transfer: ~$0-5/month"
    ssl_certificate   = var.domain_name != "" ? "SSL Certificate: Free (ACM)" : "SSL Certificate: N/A"
    total_estimate    = "Total: ~$30-60/month (depending on usage)"
  }
}

# Security Information
output "security_notes" {
  description = "Security configuration notes"
  value = {
    encryption = {
      ecr_images      = "AES256 encryption enabled"
      cloudwatch_logs = "KMS encryption enabled"
      s3_buckets      = "KMS encryption enabled for all S3 buckets"
      alb_traffic     = var.domain_name != "" ? "HTTPS/TLS encryption" : "HTTP only (consider enabling HTTPS)"
    }
    network_security = {
      alb_access     = "Internet accessible on ports 80${var.domain_name != "" ? " (redirect) and 443" : " only"}"
      ecs_access     = "Only accessible from ALB"
      s3_access      = "Private buckets with proper IAM policies"
      container_port = "Port ${var.container_port} only accessible via load balancer"
    }
    recommendations = [
      "Enable deletion protection for production load balancer",
      "Configure domain name and SSL certificate for HTTPS",
      "Review and customize IAM policies for least privilege",
      "Enable ALB access logs for production monitoring",
      "Consider using Fargate Spot for cost optimization in non-production environments",
      "Set up CloudTrail for API logging",
      "Configure S3 bucket policies for fine-grained access control",
      "Consider implementing document retention policies"
    ]
  }
}
