# One-Click DevSecOps Infrastructure Deployment Script for Windows
# Antigravity AI Orchestrator

$ErrorActionPreference = "Stop"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " 🚀 AWS DevSecOps Architecture One-Click Deployer" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# ─── Prerequisite Checks ─────────────────────────────────────────────
Write-Host "🔍 Checking local requirements..." -ForegroundColor Yellow

$tools = @{
    "terraform" = "Terraform"
    "aws"       = "AWS CLI"
    "kubectl"   = "Kubectl"
}

foreach ($tool in $tools.Keys) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Error: $($tools[$tool]) is not installed or not in system PATH." -ForegroundColor Red
        Write-Host "Please install it before running this deployment." -ForegroundColor Yellow
        Exit 1
    }
}
Write-Host "✅ All local CLI tools found (Terraform, AWS CLI, Kubectl)" -ForegroundColor Green

# Verify AWS CLI holds active credentials
$identity = aws sts get-caller-identity --query "Account" --output text 2>$null
if (-not $identity) {
    Write-Host "❌ Error: AWS CLI is not configured or credentials expired." -ForegroundColor Red
    Write-Host "Please run 'aws configure' and try again." -ForegroundColor Yellow
    Exit 1
}
Write-Host "✅ AWS credentials verified (Account: $identity)" -ForegroundColor Green
Write-Host ""

# ─── Provisioning AWS Infrastructure via Terraform ───────────────────
Write-Host "⚙️  Initializing and provisioning AWS Infrastructure via Terraform..." -ForegroundColor Yellow
Set-Location "terraform-iac"

Write-Host "⚡ Running 'terraform init'..." -ForegroundColor Gray
terraform init

Write-Host "⚡ Running 'terraform apply -auto-approve'..." -ForegroundColor Gray
Write-Host "⚠️  Note: Provisioning VPC, EKS Cluster, ALB Controller, and Jenkins EC2 may take 10-15 minutes." -ForegroundColor Yellow
terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform provisioning failed!" -ForegroundColor Red
    Exit 1
}

Write-Host "✅ AWS Infrastructure successfully provisioned!" -ForegroundColor Green
Write-Host ""

# ─── Gather Infrastructure Outputs ───────────────────────────────────
Write-Host "📊 Fetching infrastructure deployment outputs..." -ForegroundColor Yellow
$clusterName = terraform output -raw cluster_name
$jenkinsIp = terraform output -raw jenkins_public_ip
$jenkinsUrl = terraform output -raw jenkins_url
$sonarUrl = terraform output -raw sonarqube_url
$prometheusUrl = terraform output -raw prometheus_url
$grafanaUrl = terraform output -raw grafana_url

Set-Location ".."

# ─── Configure Kubeconfig context ────────────────────────────────────
Write-Host "🔌 Connecting local kubectl to EKS Cluster ($clusterName)..." -ForegroundColor Yellow
aws eks update-kubeconfig --region us-east-1 --name $clusterName

# ─── Deploying Kubernetes manifests ──────────────────────────────────
Write-Host "⛵ Deploying 3-tier App on EKS ($clusterName)..." -ForegroundColor Yellow
kubectl apply -f myk8s/

Write-Host "⏳ Waiting for App rollout to complete (3-tier Flask App)..." -ForegroundColor Yellow
kubectl rollout status deployment/myflask-app -n flask-sql-namespace --timeout=300s

# ─── Retrieve ALB Ingress Endpoint ───────────────────────────────────
Write-Host "🌐 Fetching public Application Load Balancer Ingress URL..." -ForegroundColor Yellow
$albUrl = ""
$attempts = 0
$maxAttempts = 15

while (-not $albUrl -and $attempts -lt $maxAttempts) {
    Start-Sleep -Seconds 10
    $albUrl = kubectl get ingress myflask-app-ingress -n flask-sql-namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    $attempts++
    Write-Host "." -NoNewline
}
Write-Host ""

# ─── Print Welcome Summary Banner ───────────────────────────────────
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " 🎉 ARCHITECTURE SUCCESSFULLY DEPLOYED ON AWS! 🎉" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📍 3-Tier Application URL:  http://$albUrl" -ForegroundColor Cyan
Write-Host "📍 Jenkins Server URL:      $jenkinsUrl" -ForegroundColor Cyan
Write-Host "📍 SonarQube Server URL:    $sonarUrl" -ForegroundColor Cyan
Write-Host "📍 Prometheus Server URL:  $prometheusUrl" -ForegroundColor Cyan
Write-Host "📍 Grafana Server URL:     $grafanaUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔒 Jenkins SSH access disabled as requested. Connect safely via Systems Manager (SSM) Session Manager." -ForegroundColor Yellow
Write-Host "To teardown/destroy this environment later, run: cd terraform-iac; terraform destroy -auto-approve" -ForegroundColor Gray
Write-Host "======================================================================" -ForegroundColor Green
