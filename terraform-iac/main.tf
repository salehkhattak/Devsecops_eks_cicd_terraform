locals {
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
}

# ─── VPC Module ──────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  name        = "${var.app_name}-${var.environment}"
  cidr        = var.vpc_cidr
  azs         = local.azs
  environment = var.environment
}

# ─── EKS Module ──────────────────────────────────────────────────
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = var.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_instance_type = var.node_instance_type
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  node_desired_size  = var.node_desired_size
}

# ─── Load Balancer Controller Module ─────────────────────────────
module "load_balancer" {
  source = "./modules/load-balancer"

  cluster_name      = module.eks.cluster_name
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  aws_region        = var.aws_region
  environment       = var.environment

  depends_on = [module.eks]
}

# ─── Jenkins EC2 Module ──────────────────────────────────────────
module "jenkins" {
  source = "./modules/jenkins"

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  instance_type    = var.jenkins_instance_type
  app_name         = var.app_name
  environment      = var.environment
}
