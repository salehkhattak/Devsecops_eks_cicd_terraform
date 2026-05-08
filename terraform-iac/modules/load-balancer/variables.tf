variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster runs"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider (from EKS module)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the cluster is deployed"
  type        = string
}

variable "environment" {
  description = "Deployment environment label (dev / staging / prod)"
  type        = string
}
