# Three-Tier Flask Application & Infrastructure

Welcome to the **Three-Tier Flask App** repository! This project has been modernized from a simple script into a fully architected, three-tier application featuring a beautiful modern UI, asynchronous interactions, and complete infrastructure-as-code deployments ready for production AWS environments.

---

## 🏗️ Architecture Overview

The application is structured into a clean **3-Tier Architecture**:
1. **Presentation Tier (`frontend/`)**: 
   - A highly polished HTML/CSS/JS frontend using *Glassmorphism* aesthetics, Google Fonts (`Inter`), FontAwesome, and dynamic micro-animations.
   - Decoupled from the backend, pulling and posting data via asynchronous fetching.
   - Includes real-time toast notifications and instant-reacting "Like" buttons.
2. **Application Tier (`backend/app/`)**: 
   - Serves as the API processing layer written in Flask.
   - Segregates concerns into `routes.py`, `services.py` (Business Logic), and `models.py` (Data Access).
3. **Data Tier (`MySQL`)**: 
   - Robustly stores messages, augmented to include `author`, `likes`, and `created_at` timestamps using automated schema migrations built into the backend model layer.

---

## 💻 Development Side (Local Setup)

For local development and testing, you can use **Docker Compose**.

### Prerequisites
- Docker & Docker Compose
- Git

### Running Locally
1. Clone the repository and navigate into the folder:
   ```bash
   git clone https://github.com/your-username/flask-sql-app.git
   cd flask-sql-app
   ```

2. Start the local multi-container environment:
   ```bash
   docker-compose up --build -d
   ```

3. **Access the application:**
   - Open your browser and navigate to `http://localhost:5000`
   - You can submit messages with authors, like messages, and enjoy the polished UI!

4. **Shutdown the environment:**
   ```bash
   docker-compose down
   ```

### Manual Docker Deployment (Without Compose)
If you wish to test container interaction natively:
```bash
# 1. Create a custom network
docker network create twotier

# 2. Spin up the MySQL Data Tier
docker run -d --name mysql -v mysql-data:/var/lib/mysql --network=twotier \
    -e MYSQL_DATABASE=mydb -e MYSQL_ROOT_PASSWORD=admin -p 3306:3306 mysql:5.7

# 3. Build and run the Flask App Application/Presentation Tier
docker build -t three-tier-flask-app .
docker run -d --name flaskapp --network=twotier \
    -e MYSQL_HOST=mysql -e MYSQL_USER=root -e MYSQL_PASSWORD=admin -e MYSQL_DB=mydb \
    -p 5000:5000 three-tier-flask-app:latest
```

---

## 🚀 Production Side (DevOps & IaC)

The repository provides everything required to transition from local development to a highly scalable production setup on AWS Elastic Kubernetes Service (EKS).

### 1. **Jenkins CI/CD Pipeline (`Jenkinsfile`)**
The provided pipeline stages automate the entire software delivery lifecycle:
- Code Clone & File system scan using **Trivy**.
- Builds the `three-tier-flask-app` container using our optimized Dockerfile.
- Pushes the built container to Docker Hub securely.
- Automatically handles email notifications on Success or Failure.

### 2. **Terraform Infrastructure as Code (`terraform-iac/`)**
The project provides complete declarative configuration to bootstrap your foundation:
- **`terraform-iac/`**: Deploys an AWS Virtual Private Cloud (VPC) with public/private subnets and NAT gateways alongside an EKS Managed Node Group natively configured using Hashicorp Modules.
- **`remote-infra/`**: Bootstraps securing your terraform `.tfstate` remotely using Amazon S3 for storage and DynamoDB for lock handling.

*To provision infrastructure:*
```bash
cd terraform-iac
terraform init
terraform apply
```

### 3. **Kubernetes Deployment Manifests**
Whether you test locally via Minikube or scale to production on AWS EKS, manifests are ready.

- **`myk8s/`**: Baseline manifests for local cluster testing `app-deployment.yml`, `app-svc.yml`, Persistent Volumes.
- **`eks-manifests/`**: Hardened configurations linking specifically to LoadBalancers and AWS configured ConfigMaps for Production deployment. Contains `three-tier-app-deployment.yml` and `three-tier-app-svc.yml`.

*To apply applications to your cluster:*
```bash
kubectl apply -f eks-manifests/
```

---

## 🔒 Security & Best Practices
- The MySQL schema automatically self-promotes and avoids deletion on restart.
- Docker containers use lightweight python distributions.
- Multi-stage Docker definitions (`Dockerfile-multistage`) exist to securely compile binaries separately from runtime environments.

---

## 🛠️ Troubleshooting

### Common Error: `(2002, "Can't connect to server on 'mysql' (115)")` or `(2005, "Unknown server host 'mysql' (11001)")`

**What causes this?**
This error occurs when you try to run the Flask application locally on your host machine (e.g., using `python backend/run.py` or `flask run`) while relying on the default database host configuration. By default, the application is configured to look for the database at a hostname called `mysql` (`MYSQL_HOST=mysql`). While this hostname is perfectly resolvable *inside* the Docker network created by `docker-compose`, your local Windows/Host machine doesn't know how to route the hostname `mysql` to the Docker container. 

**How it is resolved:**
There are two ways to resolve this issue:

1. **Run everything inside Docker (Recommended):**
   Simply run `docker-compose up --build -d` and access the application at `http://localhost:5000`. The containerized Flask app will seamlessly connect to the `mysql` container via Docker's internal DNS.

2. **Run Flask locally, but use Docker for the DB:**
   If you want to actively debug the Flask application on your local machine:
   - Ensure you are running the `mysql` container with the port `3307` exposed (which is now configured in `docker-compose.yml` to prevent conflicts with local MySQL installations).
   - Run the MySQL database in the background: `docker-compose up -d mysql`
   - Start the Flask backend by explicitly overriding the `MYSQL_HOST` and `MYSQL_PORT` environment variables to point to your `localhost:3307`:
     - **On Windows (PowerShell):** `$env:MYSQL_HOST="127.0.0.1"; $env:MYSQL_PORT="3307"; python backend/run.py`
     - **On Mac/Linux:** `MYSQL_HOST=127.0.0.1 MYSQL_PORT=3307 python backend/run.py`

---

### Bug: Messages Not Saving / `Can't connect to MySQL server` Inside Container

**Root Cause: Wrong `MYSQL_HOST` Default in `config.py`**

While debugging the local connection issue, `MYSQL_HOST` default was temporarily changed from `'mysql'` to `'localhost'` in `backend/config.py`:

```python
# ❌ BROKEN — causes connection failure inside Docker
MYSQL_HOST = os.environ.get('MYSQL_HOST', 'localhost')
```

This broke the containerized app because of how Docker networking works:

| Context | Correct `MYSQL_HOST` value |
|---|---|
| Running **inside Docker** (via `docker-compose`) | `mysql` (Docker's internal DNS name for the service) |
| Running **locally** on your host machine | `127.0.0.1` (passed via environment variable override) |

When the Flask container starts, Docker Compose injects `MYSQL_HOST=mysql` via the `environment:` block in `docker-compose.yml`. The `os.environ.get('MYSQL_HOST', 'localhost')` call correctly picks this up at runtime. However, if the hardcoded **default fallback** is changed to `'localhost'`, and the environment variable injection ever fails or is missing, Flask will try to connect to a MySQL server on `localhost` **inside its own container** — where no database exists. The result is that messages appear to post (no frontend error), but nothing is actually saved.

**How It Is Fixed:**

The default in `config.py` has been reverted to `'mysql'` so it always works correctly inside Docker:

```python
# ✅ CORRECT — works in Docker; override via env var for local dev
MYSQL_HOST = os.environ.get('MYSQL_HOST', 'mysql')
```

The `docker-compose.yml` still explicitly passes `MYSQL_HOST: mysql` via its `environment:` section, which is the definitive value used at runtime. The default in `config.py` is just a safety fallback.

**Key Rule:** Never change the default fallback in `config.py` to `'localhost'`. Always use environment variable overrides for local development instead.

---

### Bug: `Unknown server host 'mysql-svc' (11001)` in Kubernetes

**Root Cause: Service Name Mismatch in Kubernetes Manifests**

The Flask app deployment (`app-deployment.yml`) had `MYSQL_HOST` set to `"mysql-svc"`, but the actual Kubernetes MySQL Service was named **`"mysql"`** (defined in `mysql-svc.yml`). In Kubernetes, pods discover each other using **DNS based on the Service's `metadata.name`** field — not a custom label or alias.

```
Flask Pod → tries to resolve hostname: "mysql-svc"  ❌ (doesn't exist)
MySQL Service → actual DNS name: "mysql"
```

Because `mysql-svc` does not resolve to anything inside the cluster, the Flask app failed to connect to MySQL on every startup, causing a `CrashLoopBackOff`.

**Diagnosis Steps:**

```bash
# Check environment variables injected into the Flask pod
kubectl describe pod <flask-pod-name> -n flask-sql-namespace

# Check the actual service names
kubectl get svc -n flask-sql-namespace
```

**How It Is Fixed:**

The `MYSQL_HOST` value in `myk8s/app-deployment.yml` was corrected to match the Service name:

```yaml
# ❌ BROKEN — no service named 'mysql-svc' exists
- name: MYSQL_HOST
  value: "mysql-svc"

# ✅ CORRECT — matches metadata.name in mysql-svc.yml
- name: MYSQL_HOST
  value: "mysql"
```

**Key Rule for Kubernetes:** The `MYSQL_HOST` value must **exactly match** the `metadata.name` of the MySQL Service manifest. Kubernetes DNS resolves `<service-name>.<namespace>.svc.cluster.local` — so the hostname your app connects to must equal the service name.

---

### Bug: `(2002, "Can't connect to server on 'mysql' (115)")` — MySQL Not Ready on Startup

**Root Cause: Race Condition — Flask Started Before MySQL Was Ready**

Even though the MySQL **Service** and **Pod** are created at the same time as the Flask pods, MySQL needs **30-60 seconds** to fully initialize its data directory and start accepting connections. When Kubernetes schedules all pods simultaneously (which it does by default), Flask starts, tries to connect to MySQL, and gets a `Connection Refused` (errno 115) because MySQL is still booting.

```
t=0s  → MySQL Pod starts (initializing data dir, can take 30-60s)
t=0s  → Flask Pod starts (immediately tries to connect to MySQL)
t=0s  → Flask: (2002) Can't connect to server on 'mysql' (115)  ❌
t=45s → MySQL: ready to accept connections
```

**Diagnosis:**

```bash
# Check Flask pod logs — if you see this at startup, it's the race condition:
kubectl logs -n flask-sql-namespace -l app=saleh-thoughts-app

# Output indicating the bug:
# Database schema initialization error: (2002, "Can't connect to server on 'mysql' (115)")
```

**How It Is Fixed — `initContainer` in `app-deployment.yml`:**

An `initContainer` called `wait-for-mysql` was added to the Flask deployment. InitContainers run **before** the main container starts, and Kubernetes guarantees the main container won't launch until all initContainers exit successfully. The init container polls MySQL on port 3306 every 3 seconds until it accepts connections:

```yaml
initContainers:
- name: wait-for-mysql
  image: busybox:1.35
  command:
  - sh
  - -c
  - |
    echo "Waiting for MySQL to be ready..."
    until nc -z mysql 3306; do
      echo "MySQL is not ready yet — sleeping 3s"
      sleep 3
    done
    echo "MySQL is ready!"
```

**Startup sequence after the fix:**

```
t=0s   → MySQL Pod starts (initializing)
t=0s   → Flask initContainer starts — polls nc -z mysql 3306 every 3s
t=45s  → MySQL ready → nc -z mysql 3306 succeeds → initContainer exits
t=45s  → Flask main container starts — MySQL is guaranteed to be ready ✅
```

**Key Rule:** In Kubernetes, never assume a dependent service is ready just because its pod is Running. Always use `initContainers` or readiness probes to gate startup on dependency availability.

---

## ⚙️ Useful Commands

```bash
# Run full local stack with Docker
docker-compose up --build -d

# Apply all Kubernetes manifests
kubectl apply -f myk8s/

# Port-forward app to local machine (access at http://localhost:8080)
kubectl port-forward service/saleh-thoughts-app -n flask-sql-namespace 8080:80

#argocd port forwarding
kubectl port-forward svc/argocd-server -n argocd 8081:443

# Check pod status (look for initContainer status too)
kubectl get pods -n flask-sql-namespace -o wide

# Watch initContainer progress during startup
kubectl logs -n flask-sql-namespace <pod-name> -c wait-for-mysql

# Stream Flask app logs
kubectl logs -f <pod-name> -n flask-sql-namespace

# Check all services and their endpoints
kubectl get svc,endpoints -n flask-sql-namespace
```


# JENKINS INSTALLATION GUIDE (Ubuntu 22.04)
# Update packages
sudo apt update

# Install Java (required for Jenkins)
sudo apt install openjdk-17-jdk -y

# Verify Java
java -version

# Add Jenkins key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update packages again
sudo apt update

# Install Jenkins
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins

# Enable Jenkins on boot
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins


# JENKINS INSTALLATION GUIDE DOCKER
# Pull Jenkins image
docker pull jenkins/jenkins:lts
# Run Jenkins container
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --privileged \
  3-tier-flask-app-jenkins

  Service	URL
Jenkins	http://localhost:8080
SonarQube	http://localhost:9000
Grafana	http://localhost:3000
Prometheus	http://localhost:9090
Flask App	http://localhost:5000

# argocd port forwarding
kubectl port-forward svc/argocd-server -n argocd 8081:443
# argocd initial password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

for windows:
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"

#decode the password using PowerShell
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("YWRtaW4xMjM0NTY="))

Login:
Username: admin
Password: (output above)

# stop argocd 
kubectl delete pod -n argocd --all

# for individually running docker-compose services
docker compose up -d mysql flask-app jenkins