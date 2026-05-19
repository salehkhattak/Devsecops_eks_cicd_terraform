#!/usr/bin/env bash
# Simplified deploy script: readable, step-by-step, and safe to explain.

set -euo pipefail

TERRAFORM_DIR="terraform-iac"
K8S_MANIFEST_DIR="myk8s"
AWS_REGION="us-east-1"

# Simple checker for required commands
check_tools() {
  for cmd in terraform aws kubectl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: $cmd is not installed or missing from PATH."
      exit 1
    fi
  done
}

# Run terraform to provision infra (non-interactive)
provision_infra() {
  echo "-> Initializing Terraform in $TERRAFORM_DIR"
  (cd "$TERRAFORM_DIR" && terraform init)

  echo "-> Applying Terraform (this may take several minutes)"
  (cd "$TERRAFORM_DIR" && terraform apply -auto-approve)
}

# Configure kubectl to use the created EKS cluster
configure_kubectl() {
  local cluster_name
  cluster_name=$(cd "$TERRAFORM_DIR" && terraform output -raw cluster_name)
  echo "-> Updating kubeconfig for cluster: $cluster_name"
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$cluster_name"
}

# Deploy Kubernetes manifests and wait for rollout
deploy_k8s_app() {
  echo "-> Applying Kubernetes manifests from $K8S_MANIFEST_DIR"
  kubectl apply -f "$K8S_MANIFEST_DIR"

  echo "-> Waiting for deployment rollout (deployment/myflask-app)"
  kubectl rollout status deployment/myflask-app -n flask-sql-namespace --timeout=300s
}

# Fetch a basic summary of URLs from terraform outputs
print_summary() {
  echo "\nDeployment summary (from terraform outputs):"
  (cd "$TERRAFORM_DIR" && terraform output)
  echo "\nTo tear down: cd $TERRAFORM_DIR && terraform destroy -auto-approve"
}

main() {
  check_tools
  provision_infra
  configure_kubectl
  deploy_k8s_app
  print_summary
}

# Allow running individual steps for debugging, e.g. ./deploy.simplified.sh provision
if [ "$#" -gt 0 ]; then
  "$@"
else
  main
fi
