# Three-Tier Flask Application & DevSecOps CI/CD on EKS

A fully automated DevSecOps pipeline for a Three-Tier Flask application deployed on AWS EKS.  
The pipeline covers **security scanning → Docker build → image push → Kubernetes deployment** using a Jenkins Shared Library.

---

## 🏗️ Architecture Overview

```
Presentation  →  frontend/      (HTML/CSS/JS — Glassmorphism UI)
Application   →  backend/app/   (Flask — routes, services, models)
Data          →  MySQL          (Persistent via Kubernetes PVC)
```

---

## 🚀 CI/CD Pipeline (Jenkinsfile)

The pipeline is driven by a **Jenkins Shared Library** (`@Library("Shared")`).  
All reusable steps live in the `vars/` folder as Groovy files.

### Pipeline Stages

| Stage | Shared Library Call | What it does |
|---|---|---|
| Code Clone | _(built-in)_ | Clones `main` branch from GitHub |
| Trivy FS Scan | `trivyScan()` | Scans the filesystem for HIGH/CRITICAL CVEs |
| OWASP Scan | `owaspScan()` | Runs OWASP Dependency-Check via Jenkins plugin |
| SonarQube Analysis | `sonarScan()` | Static code analysis via SonarQube server |
| Docker Build | _(built-in)_ | Builds `salehktk005/saleh-thoughts-app:<BUILD_NUMBER>` |
| Trivy Image Scan | `trivyImageScan(image)` | Scans the built Docker image for HIGH/CRITICAL CVEs |
| Docker Push | `dockerPush(creds, image)` | Logs in and pushes image to DockerHub |
| Deploy to EKS | `k8sDeploy(image)` | Updates manifest, applies to EKS, waits for rollout |

### Post Actions
- ✅ **Success** → Slack notification to `#devops`
- ❌ **Failure** → Slack notification to `#devops`
- 🧹 **Always** → `cleanWs()` cleans the workspace

---

## 📁 Shared Library (`vars/`)

> **Repo:** Configure this Git repo as a Jenkins Shared Library named `Shared`  
> **Jenkins path:** Manage Jenkins → System → Global Pipeline Libraries

| File | Function | Description |
|---|---|---|
| `trivyScan.groovy` | `trivyScan()` | Trivy filesystem scan |
| `trivyImageScan.groovy` | `trivyImageScan(image)` | Trivy Docker image scan |
| `owaspScan.groovy` | `owaspScan()` | OWASP Dependency-Check (Jenkins plugin) |
| `sonarScan.groovy` | `sonarScan()` | SonarQube scanner |
| `dockerPush.groovy` | `dockerPush(credId, imageTag)` | DockerHub login + push |
| `k8sDeploy.groovy` | `k8sDeploy(image)` | kubectl apply + rollout status |

---

## 💻 Local Development

### Run with Docker Compose

```bash
git clone https://github.com/salehkhattak/Devsecops_eks_cicd_terraform.git
cd Devsecops_eks_cicd_terraform
docker-compose up --build -d
# App → http://localhost:5000
docker-compose down
```

### Run Manually (Without Compose)

```bash
# 1. Create network
docker network create twotier

# 2. Start MySQL
docker run -d --name mysql --network=twotier \
  -e MYSQL_DATABASE=mydb -e MYSQL_ROOT_PASSWORD=admin \
  -p 3306:3306 mysql:5.7

# 3. Build and run Flask app
docker build -t three-tier-flask-app .
docker run -d --name flaskapp --network=twotier \
  -e MYSQL_HOST=mysql -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=admin -e MYSQL_DB=mydb \
  -p 5000:5000 three-tier-flask-app
```

---

## ☁️ Infrastructure (Terraform)

```bash
# Provision VPC + EKS cluster
cd terraform-iac
terraform init
terraform apply

# Bootstrap remote state (S3 + DynamoDB)
cd remote-infra
terraform init
terraform apply
```

---

## ☸️ Kubernetes Deployment

```bash
# Apply all EKS manifests
kubectl apply -f eks-manifests/

# Apply local (Minikube) manifests
kubectl apply -f myk8s/

# Check pods
kubectl get pods -n flask-sql-namespace -o wide

# Port-forward app locally
kubectl port-forward service/saleh-thoughts-app -n flask-sql-namespace 8080:80
```

---

## 🔒 Jenkins Prerequisites

| Requirement | Details |
|---|---|
| Shared Library | Name: `Shared`, points to this repo's root, `vars/` folder |
| Jenkins credential | ID: `dockerHubCreds` (Username + Password for DockerHub) |
| SonarQube server | Configured in Jenkins as `SonarQube` |
| OWASP tool | Configured in Global Tool Config as `OWASP` |
| Slack plugin | Channel: `#devops` |
| Trivy | Installed on Jenkins agent (`trivy` on PATH) |
| kubectl | Installed on Jenkins agent and configured for EKS |

---

## ⚙️ Useful Commands

```bash
# Jenkins (Ubuntu)
sudo systemctl start jenkins
sudo systemctl status jenkins

# ArgoCD port-forward
kubectl port-forward svc/argocd-server -n argocd 8081:443

# Get ArgoCD initial password (Linux)
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

# Get ArgoCD initial password (Windows PowerShell)
$encoded = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))

# SonarQube
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community

# Grafana / Prometheus (Docker Compose)
docker compose up -d
```

---

## 🌐 Service URLs (Local)

| Service | URL |
|---|---|
| Flask App | http://localhost:5000 |
| Jenkins | http://localhost:8080 |
| SonarQube | http://localhost:9000 |
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |

---

## 🛠️ Common Troubleshooting

### `Can't connect to MySQL` in Docker
- Make sure `MYSQL_HOST=mysql` in `docker-compose.yml` (matches the service name).
- Default fallback in `backend/config.py` must be `'mysql'`, not `'localhost'`.

### `Unknown server host 'mysql-svc'` in Kubernetes
- `MYSQL_HOST` in the deployment manifest must match the **`metadata.name`** of the MySQL Service exactly.

### Flask crashes before MySQL is ready
- The `initContainer` (`wait-for-mysql`) in `myk8s/app-deployment.yml` polls port 3306 every 3 seconds until MySQL accepts connections before allowing the Flask container to start.

### Jenkins: `No such DSL method 'dockerPush'`
- Confirm the Shared Library is named exactly `Shared` in Jenkins → System → Global Pipeline Libraries.
- Confirm the library points to the root of this repo (the `vars/` folder must be at repo root level).