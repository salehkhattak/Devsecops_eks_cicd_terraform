# 🚀 Enterprise DevSecOps 3-Tier Architecture on AWS EKS

Welcome to the definitive production repository for the **3-Tier Flask + MySQL DevSecOps platform on AWS EKS**. This repository delivers a premium, highly secure, and fully automated deployment architecture. By pairing modern Infrastructure as Code (IaC) via modular Terraform with a state-of-the-art Jenkins DevSecOps pipeline, this repository enables absolute **one-click deployment** from zero to public URL.

---

## 🏗️ Architecture Design & Components

The application follows an enterprise-standard three-tiered separation of concerns to maximize scalability, database isolation, and security.

```
                  ┌───────────────────────────────────────────────┐
                  │                 Public Internet               │
                  └───────────────────────┬───────────────────────┘
                                          │ http (port 80)
                                          ▼
                  ┌───────────────────────────────────────────────┐
                  │          Application Load Balancer (ALB)      │
                  └───────────────────────┬───────────────────────┘
                                          │ ClusterIP routing
                                          ▼
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│ EKS Cluster (flask-app-cluster)                                                           │
│                                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ Private Network (Subnets)                                                           │  │
│  │                                                                                     │  │
│  │  ┌───────────────────────┐                    ┌───────────────────────┐             │  │
│  │  │  Flask API Frontends  │ ─── reads/writes ──│  MySQL Database Pod   │             │  │
│  │  │ (3 Replicas - HPA)    │                    │ (Single Master Replica)│             │  │
│  │  └───────────────────────┘                    └───────────┬───────────┘             │  │
│  │                                                           │                         │  │
│  │                                                           ▼                         │  │
│  │                                               ┌───────────────────────┐             │  │
│  │                                               │ Dynamic EBS Volume    │             │  │
│  │                                               │ (gp2 Storage Class)   │             │  │
│  │                                               └───────────────────────┘             │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

### 1. Presentation Tier (`frontend/`)
* **Styling & Layout:** Modern glassmorphism card layouts built using vanilla CSS with rich micro-animations.
* **Logic:** Pure JavaScript asynchronous client interface executing asynchronous queries via the browser Fetch API.
* **User Feedback:** Dynamic CSS toast notifications for error handling and system messages.

### 2. Application Tier (`backend/app/`)
* **API Framework:** Flask REST API handling data formatting, validations, and routes.
* **Modular Codebase:** Implements controller-to-service decoupling:
  * `routes.py`: API route mapping and client request parsing.
  * `services.py`: Implements domain business logic and like tracking computations.
  * `models.py`: Abstraction layer handling direct raw SQL execution.
* **Auto-Schema Migrator:** Custom database validator that automatically hooks into application bootstrap (`init_db_schema()`) and dynamically migrates tables, ensuring schema fields (`likes`, `author`, `created_at`) are created if missing.

### 3. Data Tier (MySQL 5.7)
* **Cluster Deployment:** Deployed inside the private EKS subnets as a Kubernetes workload.
* **Dynamic Persistence:** Integrates EKS default Dynamic Storage Provisioner (`gp2` class) to automatically request and attach high-performance AWS EBS volumes upon cluster startup.

---

## 📂 Project Directory Structure

```text
devsecops-eks-proj/
├── backend/                  # Flask REST application & Data abstraction
│   ├── app/
│   │   ├── __init__.py       # App builder & extension configuration
│   │   ├── models.py         # Data Access Layer & DB connection manager
│   │   ├── routes.py         # Application controllers & API routes
│   │   └── services.py       # Core business logic
│   ├── config.py             # OS Env configuration parser
│   └── run.py                # Server local/production boot entrypoint
├── frontend/                 # Presentation assets (Vanilla CSS / JS)
│   ├── static/
│   │   ├── css/              # Modern glassmorphism stylesheets
│   │   └── js/               # Dynamic asynchronous request handlers
│   └── templates/
│       └── index.html        # App web layout structure
├── myk8s/                    # EKS Production Kubernetes manifests
│   ├── app-deployment.yml   # Flask frontend configuration (replicas: 3)
│   ├── app-svc.yml          # App ClusterIP service
│   ├── hpa.yml              # Horizontal Pod Autoscaling (HPA) CPU triggers
│   ├── ingress.yml          # ALB controller Ingress routing annotations
│   ├── mysql-configmap.yml  # message.sql DB schema bootstrapping script
│   ├── mysql-deployment.yml # EKS isolated MySQL workload
│   ├── mysql-pvc.yml        # Dynamic storage volume claim
│   ├── mysql-secret.yml     # Base64-encoded MySQL system credentials
│   └── namespace.yml        # Isolated logical resource workspace
├── terraform-iac/            # Modular Infrastructure as Code
│   ├── main.tf               # Orchestrates EKS, VPC, and Jenkins modules
│   ├── variables.tf          # Tunable resource and cluster sizes
│   ├── provider.tf           # Declares AWS, Helm, Kubernetes providers
│   ├── output.tf             # Outputs ready-to-click service endpoints
│   ├── user-data.sh          # Jenkins server auto-bootstrap utility
│   └── modules/
│       ├── vpc/              # Multi-AZ VPC module with NAT gateways
│       ├── eks/              # EKS cluster module with OIDC and Core Addons
│       ├── load-balancer/    # AWS ALB Controller IAM & Helm deployment
│       └── jenkins/          # Cost-efficient SSM-enabled Jenkins EC2 module
├── deploy.ps1                # One-click deployment script (Windows PowerShell)
├── deploy.sh                 # One-click deployment script (Linux / macOS / Git Bash)
├── docker-compose.yml        # Complete local development multi-service stack
├── dockerfile                # Multi-stage optimized application container
├── Dockerfile.jenkins        # Customized Jenkins container with DinD engine
├── Makefile                  # Build and deployment helper shortcuts
└── Jenkinsfile               # Decoupled DevSecOps EKS Deployment Pipeline
```

---

## 💻 Local Development Setup

You can run the entire DevSecOps tooling, application, and database locally using either Docker Compose or via manual local networks.

### Run with Docker Compose (Recommended)
This runs the application, database, Jenkins, SonarQube, Prometheus, and Grafana on a single local docker bridge network.

```bash
# 1. Build and run all services in detached mode
docker-compose up --build -d

# 2. Verify all running containers
docker-compose ps
```

#### Local Access Dashboard:
* **Web Application:** `http://localhost:5000`
* **Jenkins Server:** `http://localhost:8080`
* **SonarQube Server:** `http://localhost:9000`
* **Prometheus Server:** `http://localhost:9090`
* **Grafana Dashboards:** `http://localhost:3000`

```bash
# Teardown the local environment
docker-compose down -v
```

### Run Manually (Without Compose)
```bash
# 1. Create a logical local network
docker network create twotier-network

# 2. Spin up MySQL container
docker run -d --name mysql --network=twotier-network \
  -e MYSQL_DATABASE=mydb \
  -e MYSQL_ROOT_PASSWORD=admin \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=admin \
  -p 3306:3306 \
  mysql:5.7

# 3. Build the Flask application
docker build -t salehktk005/myflask-app:latest .

# 4. Spin up the Flask API frontend
docker run -d --name flaskapp --network=twotier-network \
  -e MYSQL_HOST=mysql \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=admin \
  -e MYSQL_DB=mydb \
  -p 5000:5000 \
  salehktk005/myflask-app:latest
```

---

## ☁️ Infrastructure as Code (IaC)

Our Terraform modules provision a production-grade AWS infrastructure optimized for price performance.

### Cost & Compute Allocations
* **EKS Managed Node Group:** Running on `t3.small` nodes to minimize unnecessary AWS costs (~$30/node/month) while maintaining stability.
* **Jenkins EC2 Server:** Running on a single `t3.small` instance (~$15/month) which builds, analyzes, and coordinates the entire infrastructure.
* **AWS SSM Integrated:** The Jenkins server runs **SSH-free**. SSH key pairs have been completely removed. Systems operators can securely connect to the terminal via the standard **AWS Systems Manager (SSM) Session Manager**.

### Provisioning Steps
```bash
cd terraform-iac
terraform init
terraform apply -auto-approve
```

---

## 🔒 Kubernetes Production Manifests (`myk8s/`)

Our Kubernetes configuration uses standard Kubernetes resources structured for maximum security:

1. **Storage Isolation:** Dynamic EBS volume provisioning is handled directly by AWS via `gp2` storage classes inside `mysql-pvc.yml`, removing the risk of storage loss.
2. **Database Auto-Seeding:** A ConfigMap (`mysql-configmap.yml`) mounts `message.sql` directly inside the MySQL initialization folder `/docker-entrypoint-initdb.d/`. Tables are constructed automatically on startup.
3. **Secret Store Integration:** Hardcoded database credentials are fully replaced with `mysql-secret.yml` Opaque Secrets. The application references credentials at runtime via the secure `secretKeyRef` driver.
4. **AWS ALB Ingress Controller:** Web traffic routes directly through the AWS ALB Ingress controller using explicit annotations inside `ingress.yml` to generate a secure, public Load Balancer IP.

---

## 🚀 DevSecOps CI/CD Pipeline (`Jenkinsfile`)

The `Jenkinsfile` provides a complete **zero-trust, multi-phase static and dynamic security scanning pipeline**.

```
[Git Clone] ──► [SonarQube Analysis] ──► [OWASP Dependency Scan] ──► [Docker Build] 
                                                                           │
                                                                           ▼
[K8s Deploy] ◄── [Docker Hub Push] ◄── [Trivy Vulnerability Scan] ◄────────┘
```

### Pipeline Execution Phases:
1. **Code Clone:** Pulls codebase from the repository.
2. **SonarQube Analysis:** Executes automated static code quality analysis and scans for logic vulnerability patterns.
3. **OWASP Dependency Scan:** Audits Python package dependencies for known database security CVE exploits.
4. **Docker Build:** Packages the application using optimized Python slim layers.
5. **Trivy Image Scan:** Audits the newly compiled container layers for system library security vulnerabilities.
6. **Docker Hub Registry Push:** Pushes the secure container image with unique build numbers to Docker Hub.
7. **Production K8s Deploy:** Reconfigures EKS context, replaces the manifest tag dynamically, deploys to Kubernetes, and validates rollout health.

---

## ⚡ One-Click Automated Deployments

We provide automated deployment scripts that check prerequisites, provision infrastructure, and handle app rollouts.

### Windows (PowerShell)
```powershell
# Open PowerShell in workspace root
.\deploy.ps1
```

### Linux / macOS / Git Bash
```bash
# Open bash terminal in workspace root
chmod +x deploy.sh
./deploy.sh
```

---

## 🛠️ Notable Bugs Resolved

Here is a list of major production-level bugs resolved during EKS migration:

* **EKS Dynamic Volume Mounts:** Removed static host-path bindings. MySQL PVC now mounts natively to AWS EBS using `gp2` storage class controllers.
* **Groovy sed Substitution:** Corrected `Jenkinsfile` K8s deploy command context. Swapped single quoted groovy strings (`sh '...'`) with double quotes (`sh "..."`) to ensure image tags are expanded prior to execution on EKS.
* **EKS Kubeconfig Context Injection:** Added automated EKS context configurations (`aws eks update-kubeconfig`) to EKS deploy stages. Jenkins runs with local EKS context without authentication blocks.
* **Kubectl NodePort Mismatch:** App service changed from NodePort to ClusterIP. Deployed Ingress manifests for AWS ALB routing.
* **Bash Syntax Continuation Errors:** Fixed SonarQube and OWASP multiline script builders to use proper Unix format slashes (`\`) instead of Windows backticks (`` ` ``) in Jenkinsfile stages.
* **Database Credentials Secrets Mapping:** Plaintext YAML env keys were removed and substituted with K8s environment references mapping directly to Base64 encoded Kubernetes secrets.