# Enterprise CI/CD Pipeline (GitHub Actions + Docker + Terraform + ECR + EKS)

**Version:** v1.1.0 (Generated 2026-02-14)

A production-style CI/CD repo that demonstrates how to:
- provision an **ECR repo** and an **OIDC-based IAM role** for GitHub Actions (no long-lived AWS keys),
- build and push a **Docker image** on every commit,
- deploy to an existing **EKS** cluster using **Helm** (or kubectl), and
- keep everything documented and repeatable.

---

## Architecture

![Architecture](docs/architecture.png)

### Flow Summary
1. Developer pushes code to GitHub.
2. GitHub Actions assumes an AWS IAM role via **OIDC**.
3. Pipeline builds a Docker image and pushes it to **Amazon ECR**.
4. Pipeline updates the running app on **EKS** using Helm (`helm upgrade --install`).
5. (Optional) Observability tools can watch deployment health (not required for this project).

---

## What’s in this repo

```text
enterprise-cicd-pipeline/
├── app/                          # sample app (Flask)
│   ├── app.py
│   └── requirements.txt
├── Dockerfile
├── helm/demo-api/                # Helm chart used by pipeline deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── terraform/                    # IaC: ECR + GitHub OIDC IAM role
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── .github/workflows/
│   ├── ci-build-push.yml         # build + push to ECR
│   └── cd-deploy-eks.yml         # deploy to EKS with Helm
└── docs/
    └── architecture.png
```

---

## Prerequisites

### Accounts & Access
- An **AWS account** where you can create IAM roles and ECR repositories.
- An existing **EKS cluster** (you can use Project 1’s EKS platform, or your own).
- A GitHub repo where you’ll push this code.

### Tools (local)
- Terraform >= 1.6
- AWS CLI v2
- kubectl
- Helm

---

## Step 1 — Provision AWS resources (Terraform)

This project provisions:
- an **ECR repository** for your Docker images
- an **IAM role** that GitHub Actions can assume using **OIDC**
- IAM permissions: push to ECR + deploy to EKS (via `eks:DescribeCluster`)

### 1.1 Configure Terraform variables
Copy example and edit:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform/terraform.tfvars`:
- `aws_region`
- `ecr_repo_name`
- `github_org`
- `github_repo`
- `eks_cluster_name`

### 1.2 Apply Terraform
```bash
terraform init
terraform apply -auto-approve
```

### 1.3 Capture outputs
Terraform will output:
- `ecr_repository_url`
- `github_actions_role_arn`

You will paste these into GitHub Secrets.

---

## Step 2 — Configure GitHub Secrets

In GitHub: **Settings → Secrets and variables → Actions**

Add these secrets:

- `AWS_REGION` = e.g. `us-east-1`
- `AWS_ROLE_ARN` = Terraform output `github_actions_role_arn`
- `ECR_REPOSITORY` = Terraform output `ecr_repository_url`
- `EKS_CLUSTER_NAME` = your cluster name (same as terraform var)
- `K8S_NAMESPACE` = `demo` (or your preferred namespace)

> No AWS access keys required. The pipeline uses OIDC + role assumption.

---

## Step 3 — Run CI (build + push)

Workflow: `.github/workflows/ci-build-push.yml`

**Trigger:** push to `main` (or manual dispatch)

What it does:
- builds Docker image
- tags image with commit SHA
- pushes image to ECR

---

## Step 4 — Run CD (deploy to EKS)

Workflow: `.github/workflows/cd-deploy-eks.yml`

**Trigger:** after CI completes (and on manual dispatch)

What it does:
- updates kubeconfig for the cluster
- deploys/updates release via Helm
- sets the container image tag to the commit SHA

---

## How to verify deployment

### Option A: Check Kubernetes resources
```bash
kubectl -n demo get deploy,svc,ingress
kubectl -n demo describe deploy demo-api
```

### Option B: Port-forward locally
```bash
kubectl -n demo port-forward svc/demo-api 8080:80
curl http://localhost:8080/health
```

Expected:
```json
{"status":"ok"}
```

---

## Rollback strategy (simple, practical)
If a deploy breaks, roll back Helm:

```bash
helm -n demo history demo-api
helm -n demo rollback demo-api <REVISION>
```

---

## Notes for “FAANG-style” polish
To make this portfolio stand out even more, add:
- environment separation (dev/stage/prod)
- security scanning (Trivy, Snyk) in CI
- policy-as-code (OPA/Gatekeeper) in CD
- deployment strategies (canary/blue-green)
- SLOs + alerting

---

## Security scanning (Trivy + SARIF)

CI now runs **Trivy** to scan the built Docker image for **HIGH/CRITICAL** vulnerabilities and uploads results as **SARIF** to GitHub’s Security tab.

Where to look:
- `.github/workflows/ci-build-push.yml`

You’ll see findings under:
- GitHub → **Security** → **Code scanning alerts**

---

## Environment promotion (dev → staging → prod)

CD supports environment promotion using GitHub **Environments**.
- `dev` deploys automatically after CI (workflow_run)
- `staging` and `prod` are recommended to be **manual dispatch** with **required reviewers**.

### Configure Environments in GitHub
1. GitHub repo → **Settings → Environments**
2. Create environments: `dev`, `staging`, `prod`
3. For `staging` and `prod`, set:
   - **Required reviewers** (approval gate)
4. (Optional) Add environment variables:
   - `PROGRESSIVE_DELIVERY=true` to enable Argo Rollouts canary mode

Run deployment manually:
- Actions → **CD - Deploy to EKS (Promotion)** → Run workflow
- Choose environment and optional `image_tag`

---

## Slack/Teams notifications (optional)

Add secret:
- `SLACK_WEBHOOK_URL`

Then every CD run will post a notification.

---

## Progressive delivery (optional) - Argo Rollouts canary

This repo includes an optional canary deployment using Argo Rollouts.
Docs:
- `docs/argo-rollouts.md`

Enable it by setting a GitHub environment variable:
- `PROGRESSIVE_DELIVERY=true`


## Cleanup
Destroy Terraform resources:
```bash
cd terraform
terraform destroy -auto-approve
```
