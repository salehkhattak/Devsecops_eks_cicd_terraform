module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = [cidrsubnet(var.cidr, 4, 0), cidrsubnet(var.cidr, 4, 1)]
  public_subnets  = [cidrsubnet(var.cidr, 4, 8), cidrsubnet(var.cidr, 4, 9)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags so EKS can discover subnets for load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = var.environment
  }
}
