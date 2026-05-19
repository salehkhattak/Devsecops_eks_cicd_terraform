# ─── VPC Outputs ─────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ─── EKS Outputs ─────────────────────────────────────────────────
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl after apply"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# ─── Load Balancer Outputs ────────────────────────────────────────
output "lb_controller_status" {
  description = "Helm release status of the AWS Load Balancer Controller"
  value       = module.load_balancer.lb_controller_status
}

# ─── Jenkins & Tooling Outputs ────────────────────────────────────
output "jenkins_public_ip" {
  description = "Public Elastic IP of the Jenkins server"
  value       = module.jenkins.jenkins_public_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = module.jenkins.jenkins_url
}

output "sonarqube_url" {
  description = "URL to access SonarQube"
  value       = module.jenkins.sonarqube_url
}

output "prometheus_url" {
  description = "URL to access Prometheus monitoring"
  value       = module.jenkins.prometheus_url
}

output "grafana_url" {
  description = "URL to access Grafana dashboards"
  value       = module.jenkins.grafana_url
}