variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)
}

variable "environment" {
  description = "Deployment environment label (dev / staging / prod)"
  type        = string
}
