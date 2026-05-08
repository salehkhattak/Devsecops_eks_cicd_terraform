module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Allow kubectl from anywhere (tighten in prod with cluster_endpoint_public_access_cidrs)
  cluster_endpoint_public_access = true

  # Enable OIDC provider — required for IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster addons — keep essential ones managed by EKS
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    app_nodes = {
      name = "${var.cluster_name}-nodes"

      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      disk_size = 30

      labels = {
        role        = "app"
        environment = var.environment
      }

      tags = {
        Environment = var.environment
      }
    }
  }

  # Allow nodes to join the cluster automatically
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = var.environment
  }
}
