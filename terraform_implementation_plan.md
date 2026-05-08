# Terraform Infrastructure Plan — VPC + EKS + Load Balancer (Modular)

## Overview

Refactor the existing flat `terraform-iac/` directory into a proper **modular Terraform structure** with three reusable modules:
- **VPC** — networking, subnets, NAT gateway, Internet Gateway
- **EKS** — managed Kubernetes cluster with node groups
- **Load Balancer** — AWS Load Balancer Controller (Helm) + IAM IRSA for in-cluster ALB/NLB support

The existing files have several issues:
- `output.tf` references raw resources (`aws_vpc.this`, `aws_subnet.public`) that don't exist — the project uses community modules, so outputs must reference `module.vpc.*`
- `main.tf` is missing the **required version pin** for `terraform-aws-modules/eks/aws` (needs `~> 20.0` for Kubernetes 1.29+)
- No `terraform.required_version` constraint
- `user-data.sh` uses a **deprecated Jenkins key URL** (the old `tee` method; should use `gpg --dearmor`)
- No Load Balancer Controller setup at all

---

## Proposed Changes

### Root module (`terraform-iac/`)

#### [MODIFY] [provider.tf](file:///d:/devops%20projects/two-tier-flask-app/terraform-iac/provider.tf)
- Add `required_version = ">= 1.5.0"` Terraform constraint
- Add `helm` and `kubernetes` providers (needed for LB Controller)

#### [MODIFY] [variables.tf](file:///d:/devops%20projects/two-tier-flask-app/terraform-iac/variables.tf)
- Add `vpc_cidr`, `environment`, `app_name` variables

#### [MODIFY] [main.tf](file:///d:/devops%20projects/two-tier-flask-app/terraform-iac/main.tf)
- Replace inline module calls with calls to the local `./modules/vpc`, `./modules/eks`, `./modules/load-balancer` modules

#### [MODIFY] [output.tf](file:///d:/devops%20projects/two-tier-flask-app/terraform-iac/output.tf)
- Fix broken references — use `module.vpc.*` and `module.eks.*` instead of raw resource refs

#### [MODIFY] [user-data.sh](file:///d:/devops%20projects/two-tier-flask-app/terraform-iac/user-data.sh)
- Fix deprecated Jenkins GPG key method
- Fix Trivy version to use a parameterized/latest approach

---

### Module: VPC (`terraform-iac/modules/vpc/`)

**[NEW]** `main.tf` — Uses `terraform-aws-modules/vpc/aws ~> 5.0` with:
- 2 public + 2 private subnets across 2 AZs
- NAT Gateway (single)
- Required EKS subnet tags (`kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb`)

**[NEW]** `variables.tf` — `name`, `cidr`, `azs`, `environment`

**[NEW]** `outputs.tf` — Exports `vpc_id`, `public_subnet_ids`, `private_subnet_ids`

---

### Module: EKS (`terraform-iac/modules/eks/`)

**[NEW]** `main.tf` — Uses `terraform-aws-modules/eks/aws ~> 20.0` with:
- Cluster version `1.29`
- Managed node group (`t3.medium`, min 1, max 3, desired 2)
- OIDC provider enabled (needed for IRSA)
- `cluster_endpoint_public_access = true`

**[NEW]** `variables.tf` — `cluster_name`, `cluster_version`, `vpc_id`, `subnet_ids`, `environment`

**[NEW]** `outputs.tf` — Exports `cluster_name`, `cluster_endpoint`, `cluster_certificate_authority_data`, `oidc_provider_arn`, `cluster_oidc_issuer_url`

---

### Module: Load Balancer (`terraform-iac/modules/load-balancer/`)

**[NEW]** `main.tf` — AWS Load Balancer Controller via Helm:
- IAM policy for ALB controller (downloads official AWS policy JSON)
- IRSA role bound to `kube-system/aws-load-balancer-controller` service account
- Helm release of `aws-load-balancer-controller` chart

**[NEW]** `variables.tf` — `cluster_name`, `vpc_id`, `oidc_provider_arn`, `aws_region`, `environment`

**[NEW]** `outputs.tf` — Exports `lb_controller_helm_release_status`

---

## Verification Plan

### CLI Validation
```bash
cd terraform-iac
terraform init
terraform validate
terraform plan
```

### Manual Verification
- Confirm `terraform validate` reports no errors
- Review `terraform plan` output to confirm VPC, EKS, and LB resources will be created

terraform-iac/
├── provider.tf          ← AWS + Helm + Kubernetes + HTTP providers
├── variables.tf         ← All tunable inputs (region, cluster, nodes)
├── main.tf              ← Calls 3 local modules
├── output.tf            ← Fixed references + kubectl config hint
├── user-data.sh         ← Fully automated EC2 bootstrap
└── modules/
    ├── vpc/
    │   ├── main.tf      ← VPC, public/private subnets, NAT GW, EKS subnet tags
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks/
    │   ├── main.tf      ← EKS cluster, OIDC/IRSA, core addons, node groups
    │   ├── variables.tf
    │   └── outputs.tf
    └── load-balancer/
        ├── main.tf      ← IAM policy (fetched from AWS), IRSA role, Helm chart
        ├── variables.tf
        └── outputs.tf
