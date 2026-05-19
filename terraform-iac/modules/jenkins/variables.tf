variable "vpc_id" {
  description = "VPC ID where Jenkins will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID where Jenkins will be placed"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.small"
}

variable "app_name" {
  description = "Application name for tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
