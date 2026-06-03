output "region" {
  description = "AWS region"
  value       = var.region
}

# --- EKS ---

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca" {
  description = "EKS cluster CA certificate (base64)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.region}"
}

# --- Networking ---

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# --- Data Layer ---

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = var.enable_elasticache ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

# --- ECR ---

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

# --- ALB Controller ---

output "alb_controller_role_arn" {
  description = "IAM role ARN for the ALB ingress controller service account"
  value       = aws_iam_role.alb_controller.arn
}

# --- Observability ---

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

# --- DNS & TLS ---

output "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS"
  value       = aws_acm_certificate.api.arn
}

output "route53_nameservers" {
  description = "NS records to configure at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

# --- Scale Commands ---

output "scale_down_command" {
  description = "Command to scale nodes to 0 (pause infrastructure)"
  value       = "aws eks update-nodegroup-config --cluster-name ${aws_eks_cluster.main.name} --nodegroup-name ${aws_eks_node_group.workers.node_group_name} --scaling-config minSize=0,maxSize=${var.node_max_size},desiredSize=0 --region ${var.region}"
}

output "scale_up_command" {
  description = "Command to scale nodes back up (resume infrastructure)"
  value       = "aws eks update-nodegroup-config --cluster-name ${aws_eks_cluster.main.name} --nodegroup-name ${aws_eks_node_group.workers.node_group_name} --scaling-config minSize=${var.node_min_size},maxSize=${var.node_max_size},desiredSize=${var.node_desired_size} --region ${var.region}"
}
