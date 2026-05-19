#!/bin/bash
# One-Click DevSecOps Infrastructure Deployment Script
# Antigravity AI Orchestrator

set -euo pipefail

# ANSI color codes
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN} 🚀 AWS DevSecOps Architecture One-Click Deployer${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo ""

# ─── Prerequisite Checks ─────────────────────────────────────────────
echo -e "${YELLOW}🔍 Checking local requirements...${NC}"

for tool in terraform aws kubectl; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}❌ Error: $tool is not installed or not in system PATH.${NC}"
        echo -e "${YELLOW}Please install it before running this deployment.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ All local CLI tools found (Terraform, AWS CLI, Kubectl)${NC}"

# Verify AWS CLI holds active credentials
if ! identity=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null); then
    echo -e "${RED}❌ Error: AWS CLI is not configured or credentials expired.${NC}"
    echo -e "${YELLOW}Please run 'aws configure' and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS credentials verified (Account: $identity)${NC}"
echo ""

# ─── Provisioning AWS Infrastructure via Terraform ───────────────────
echo -e "${YELLOW}⚙️  Initializing and provisioning AWS Infrastructure via Terraform...${NC}"
cd terraform-iac

echo -e "${GRAY}⚡ Running 'terraform init'...${NC}"
terraform init

echo -e "${GRAY}⚡ Running 'terraform apply -auto-approve'...${NC}"
echo -e "${YELLOW}⚠️  Note: Provisioning VPC, EKS Cluster, ALB Controller, and Jenkins EC2 may take 10-15 minutes.${NC}"
terraform apply -auto-approve

echo -e "${GREEN}✅ AWS Infrastructure successfully provisioned!${NC}"
echo ""

# ─── Gather Infrastructure Outputs ───────────────────────────────────
echo -e "${YELLOW}📊 Fetching infrastructure deployment outputs...${NC}"
clusterName=$(terraform output -raw cluster_name)
jenkinsIp=$(terraform output -raw jenkins_public_ip)
jenkinsUrl=$(terraform output -raw jenkins_url)
sonarUrl=$(terraform output -raw sonarqube_url)
prometheusUrl=$(terraform output -raw prometheus_url)
grafanaUrl=$(terraform output -raw grafana_url)

cd ..

# ─── Configure Kubeconfig context ────────────────────────────────────
echo -e "${YELLOW}🔌 Connecting local kubectl to EKS Cluster ($clusterName)...${NC}"
aws eks update-kubeconfig --region us-east-1 --name "$clusterName"

# ─── Deploying Kubernetes manifests ──────────────────────────────────
echo -e "${YELLOW}⛵ Deploying 3-tier App on EKS ($clusterName)...${NC}"
kubectl apply -f myk8s/

echo -e "${YELLOW}⏳ Waiting for App rollout to complete (3-tier Flask App)...${NC}"
kubectl rollout status deployment/myflask-app -n flask-sql-namespace --timeout=300s

# ─── Retrieve ALB Ingress Endpoint ───────────────────────────────────
echo -e "${YELLOW}🌐 Fetching public Application Load Balancer Ingress URL...${NC}"
albUrl=""
attempts=0
maxAttempts=15

while [ -z "$albUrl" ] && [ $attempts -lt $maxAttempts ]; do
    sleep 10
    albUrl=$(kubectl get ingress myflask-app-ingress -n flask-sql-namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    attempts=$((attempts+1))
    echo -n "."
done
echo ""

# ─── Print Welcome Summary Banner ───────────────────────────────────
echo -e "${GREEN}======================================================================${NC}"
echo -e "${GREEN} 🎉 ARCHITECTURE SUCCESSFULLY DEPLOYED ON AWS! 🎉${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo ""
echo -e "${CYAN}📍 3-Tier Application URL:  http://$albUrl${NC}"
echo -e "${CYAN}📍 Jenkins Server URL:      $jenkinsUrl${NC}"
echo -e "${CYAN}📍 SonarQube Server URL:    $sonarUrl${NC}"
echo -e "${CYAN}📍 Prometheus Server URL:  $prometheusUrl${NC}"
echo -e "${CYAN}📍 Grafana Server URL:     $grafanaUrl${NC}"
echo ""
echo -e "${YELLOW}🔒 Jenkins SSH access disabled as requested. Connect safely via Systems Manager (SSM) Session Manager.${NC}"
echo -e "${GRAY}To teardown/destroy this environment later, run: cd terraform-iac; terraform destroy -auto-approve${NC}"
echo -e "${GREEN}======================================================================${NC}"
