# ─── IAM Policy for AWS Load Balancer Controller ─────────────────
data "http" "lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lb_controller" {
  name        = "${var.cluster_name}-lb-controller-policy"
  description = "IAM policy for the AWS Load Balancer Controller"
  policy      = data.http.lb_controller_policy.response_body

  tags = {
    Environment = var.environment
  }
}

# ─── IRSA — IAM Role for the LB Controller Service Account ───────
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${var.cluster_name}-lb-controller-irsa"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = var.environment
  }
}

# Attach the downloaded policy to the IRSA role
resource "aws_iam_role_policy_attachment" "lb_controller_extra" {
  role       = module.lb_controller_irsa.iam_role_name
  policy_arn = aws_iam_policy.lb_controller.arn
}

# ─── Kubernetes Service Account ───────────────────────────────────
resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_controller_irsa.iam_role_arn
    }

    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }
}

# ─── Helm Release — AWS Load Balancer Controller ─────────────────
resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.lb_controller.metadata[0].name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lb_controller_extra,
    kubernetes_service_account.lb_controller,
  ]
}
