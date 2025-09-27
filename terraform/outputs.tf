# Outputs for Document Categoriser App Infrastructure - AWS App Runner

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = data.aws_ecr_repository.app_repository.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = data.aws_ecr_repository.app_repository.arn
}

output "apprunner_service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.app.arn
}

output "apprunner_service_id" {
  description = "ID of the App Runner service"
  value       = aws_apprunner_service.app.service_id
}

output "apprunner_service_url" {
  description = "Default URL of the App Runner service"
  value       = aws_apprunner_service.app.service_url
}

output "apprunner_service_status" {
  description = "Status of the App Runner service"
  value       = aws_apprunner_service.app.status
}

# Custom Domain Outputs (if configured)
output "custom_domain_association_id" {
  description = "ID of the custom domain association"
  value       = var.domain_name != "" ? aws_apprunner_custom_domain_association.app[0].id : null
}

output "custom_domain_dns_target" {
  description = "DNS target for custom domain (for Route 53 records)"
  value       = var.domain_name != "" ? aws_apprunner_custom_domain_association.app[0].dns_target : null
}

output "custom_domain_status" {
  description = "Status of the custom domain association"
  value       = var.domain_name != "" ? aws_apprunner_custom_domain_association.app[0].status : null
}

# IAM Role Outputs
output "apprunner_instance_role_arn" {
  description = "ARN of the App Runner instance role"
  value       = aws_iam_role.apprunner_instance_role.arn
}

output "apprunner_access_role_arn" {
  description = "ARN of the App Runner ECR access role"
  value       = aws_iam_role.apprunner_access_role.arn
}

# Application URLs
output "application_url" {
  description = "URL to access the application"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : aws_apprunner_service.app.service_url
}

output "application_url_default" {
  description = "Default App Runner URL (always HTTPS)"
  value       = aws_apprunner_service.app.service_url
}

output "application_url_custom" {
  description = "Custom domain URL (if configured)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : null
}

# Infrastructure Info
output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
  sensitive   = true
}

# Auto Scaling Configuration
output "autoscaling_configuration_arn" {
  description = "ARN of the App Runner auto scaling configuration"
  value       = aws_apprunner_auto_scaling_configuration_version.app.arn
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (USD) - App Runner Pay-per-use model"
  value = {
    app_runner_compute = "App Runner Compute: ~$3-15/month (${var.apprunner_cpu}, ${var.apprunner_memory})"
    app_runner_requests = "App Runner Requests: $0.40 per million requests"
    load_balancer     = "Load Balancer: INCLUDED (no ALB costs!)"
    ssl_certificate   = "SSL Certificate: INCLUDED (automatic HTTPS)"
    ecr_storage       = "ECR Storage: ~$0.10 per GB/month"
    data_transfer     = "Data Transfer: First 100GB free, then $0.09/GB"
    total_estimate    = "Total: ~$3-20/month (MASSIVE SAVINGS vs ECS+ALB)"
  }
}

# Security Information
output "security_notes" {
  description = "Security configuration notes"
  value = {
    encryption = {
      ecr_images      = "AES256 encryption enabled"
      https_traffic   = "Automatic HTTPS/TLS encryption"
      managed_certificates = "Automatic SSL certificate management"
    }
    network_security = {
      access_control  = "App Runner manages network security automatically"
      ddos_protection = "Built-in DDoS protection"
      waf_integration = "Can integrate with AWS WAF if needed"
    }
    recommendations = [
      "Configure custom domain for production use",
      "Review and customize IAM policies for least privilege",
      "Monitor App Runner logs and metrics",
      "Consider using AWS WAF for additional protection",
      "App Runner automatically handles security patches and updates"
    ]
  }
}

# Deployment Information
output "deployment_info" {
  description = "Information about the deployment"
  value = {
    service_type = "AWS App Runner"
    auto_scaling = "Automatic based on traffic (${var.min_size}-${var.max_size} instances)"
    auto_deploy  = var.auto_deployments_enabled ? "Enabled - deploys on ECR image push" : "Disabled"
    https_ready  = "Automatic HTTPS with managed certificates"
    cost_model   = "Pay-per-use (compute time + requests)"
    maintenance  = "Fully managed - no server management required"
  }
}
