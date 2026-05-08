#!/bin/bash
set -euo pipefail
exec > /var/log/user-data.log 2>&1

echo "=========================================="
echo " EC2 Bootstrap Started: $(date)"
echo "=========================================="

export DEBIAN_FRONTEND=noninteractive

# ─── System Update ────────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  curl \
  wget \
  unzip \
  git \
  gnupg \
  lsb-release \
  ca-certificates \
  apt-transport-https \
  software-properties-common \
  jq \
  bash-completion

# ─── Docker ───────────────────────────────────────────────────────
echo "--- Installing Docker ---"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker ubuntu

echo "Docker version: $(docker --version)"

# ─── Java 17 ─────────────────────────────────────────────────────
echo "--- Installing Java 17 ---"
apt-get install -y openjdk-17-jdk
echo "Java version: $(java -version 2>&1 | head -1)"

# ─── Jenkins ─────────────────────────────────────────────────────
echo "--- Installing Jenkins ---"
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

systemctl enable --now jenkins

# Add jenkins user to docker group so Jenkins can run Docker commands
usermod -aG docker jenkins

echo "Jenkins status: $(systemctl is-active jenkins)"

# ─── AWS CLI v2 ───────────────────────────────────────────────────
echo "--- Installing AWS CLI v2 ---"
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/awscliv2.zip /tmp/aws

echo "AWS CLI version: $(aws --version)"

# ─── kubectl ─────────────────────────────────────────────────────
echo "--- Installing kubectl ---"
KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
  -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

echo "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# ─── eksctl ──────────────────────────────────────────────────────
echo "--- Installing eksctl ---"
EKSCTL_VERSION=$(curl -fsSL https://api.github.com/repos/eksctl-io/eksctl/releases/latest \
  | jq -r '.tag_name')
curl -fsSL "https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" \
  | tar -xz -C /usr/local/bin
chmod +x /usr/local/bin/eksctl

echo "eksctl version: $(eksctl version)"

# ─── Helm ────────────────────────────────────────────────────────
echo "--- Installing Helm ---"
curl -fsSL https://baltocdn.com/helm/signing.asc \
  | gpg --dearmor -o /usr/share/keyrings/helm.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] \
  https://baltocdn.com/helm/stable/debian/ all main" \
  | tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null

apt-get update -y
apt-get install -y helm

echo "Helm version: $(helm version --short)"

# ─── Trivy ───────────────────────────────────────────────────────
echo "--- Installing Trivy ---"
TRIVY_VERSION=$(curl -fsSL https://api.github.com/repos/aquasecurity/trivy/releases/latest \
  | jq -r '.tag_name' | sed 's/v//')
curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.deb" \
  -o /tmp/trivy.deb
dpkg -i /tmp/trivy.deb
rm -f /tmp/trivy.deb

echo "Trivy version: $(trivy --version)"

# ─── kubectl bash completion ──────────────────────────────────────
kubectl completion bash > /etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/ubuntu/.bashrc

# ─── Verify all tools ────────────────────────────────────────────
echo ""
echo "=========================================="
echo " EC2 Bootstrap Complete: $(date)"
echo "=========================================="
echo ""
echo "Tool Summary:"
echo "  Docker   : $(docker --version)"
echo "  Java     : $(java -version 2>&1 | head -1)"
echo "  Jenkins  : $(systemctl is-active jenkins)"
echo "  AWS CLI  : $(aws --version)"
echo "  kubectl  : $(kubectl version --client --short 2>/dev/null || echo 'installed')"
echo "  eksctl   : $(eksctl version)"
echo "  Helm     : $(helm version --short)"
echo "  Trivy    : $(trivy --version | head -1)"
echo "  Git      : $(git --version)"
echo ""
echo " All tools installed. EC2 is ready!"