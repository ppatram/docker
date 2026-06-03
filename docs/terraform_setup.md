# EKS Training Infrastructure — Setup Guide

## Prerequisites

### Local Tools

| Tool | Minimum Version | Purpose |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.5.0 | Infrastructure provisioning |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | 2.x | AWS authentication and EKS kubeconfig |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.29+ | Kubernetes cluster interaction |
| [Helm](https://helm.sh/docs/intro/install/) | 3.x | Installing cluster add-ons |

### AWS Account

- An AWS account with billing enabled (Free plan or Paid plan)
- An IAM user or role with **AdministratorAccess** (for training; scope down for production)
- AWS credentials configured locally:
  ```bash
  aws configure
  # or export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
  ```
- Sufficient service quotas for: EKS clusters, EC2 instances (t3.medium), VPCs, Elastic IPs, NAT Gateways

### Billing Safeguard

Set a billing alarm before deploying:
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "billing-alarm-50" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions <your-sns-topic-arn> \
  --dimensions Name=Currency,Value=USD \
  --region us-east-1
```

---

## Module Structure

```
terraform/
├── versions.tf          # Provider version constraints (aws ~> 5.50, tls, random)
├── variables.tf         # All input variables with descriptions and defaults
├── terraform.tfvars     # Training-optimized values (override defaults here)
├── main.tf              # VPC, subnets, IGW, NAT Gateway, route tables, security groups
├── eks.tf               # EKS cluster, OIDC provider, IAM roles, managed node group
├── data.tf              # RDS PostgreSQL, ElastiCache Redis, Secrets Manager
├── ecr.tf               # ECR repository with image scanning and lifecycle policies
├── alb.tf               # AWS Load Balancer Controller IRSA role and IAM policy
├── observability.tf     # CloudWatch log groups, SNS alert topic, CloudWatch alarms
├── outputs.tf           # Cluster info, endpoints, scale up/down commands
└── post-apply.sh        # Installs Helm add-ons after cluster is ready
```

---

## What Each File Provisions

### main.tf — Networking

- VPC with configurable CIDR (default `10.0.0.0/16`)
- Public subnets (ALB, NAT Gateway) with internet gateway
- Private subnets (EKS worker nodes) routed through NAT gateway
- Data subnets (RDS, ElastiCache) with no direct internet access
- Three security groups enforcing tier separation:
  - **ALB SG**: allows HTTPS (443) inbound
  - **Nodes SG**: allows port 8080 from ALB SG only
  - **Data SG**: allows 5432 (PostgreSQL) and 6379 (Redis) from Nodes SG only

### eks.tf — Compute

- EKS cluster with private API endpoint and audit logging
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Managed node group (scalable to 0 for cost savings)
- IAM roles with policies for worker nodes (ECR pull, CNI, SSM)

### data.tf — Data Layer

- RDS PostgreSQL instance (encrypted, private, no public access)
- ElastiCache Redis replication group (optional, disabled by default)
- Random password generation for DB credentials
- Secrets Manager secret storing DB connection details as JSON

### ecr.tf — Container Registry

- ECR repository with immutable tags and scan-on-push
- Lifecycle policy to expire untagged images after 7 days

### alb.tf — Ingress

- IRSA role for AWS Load Balancer Controller
- Full IAM policy granting ELB, EC2, WAF, and ACM permissions
- The controller itself is installed by `post-apply.sh` via Helm

### observability.tf — Monitoring

- CloudWatch log groups for application and EKS cluster logs
- SNS topic for alert delivery
- CloudWatch alarms: node CPU > 80%, memory > 80%, pod restarts > 3

---

## Deployment

### 1. Initialize and Apply

```bash
cd terraform
terraform init
terraform plan        # Review what will be created
terraform apply       # Provision infrastructure (~20-25 minutes)
```

### 2. Install Cluster Add-ons

```bash
./post-apply.sh
```

This installs:
- **metrics-server** — required for Horizontal Pod Autoscaler
- **AWS Load Balancer Controller** — creates ALBs from Ingress resources
- **External Secrets Operator** — syncs Secrets Manager into K8s Secrets
- **Application namespaces** — `api-dev`, `api-qa`, `api-prod`
- **ClusterSecretStore** — connects ESO to AWS Secrets Manager

### 3. Verify

```bash
kubectl get nodes              # Should show 2 Ready nodes
kubectl get pods -A            # All system pods Running
kubectl get ns                 # api-dev, api-qa, api-prod exist
```

---

## Cost Management

### Pause (scale nodes to 0)

```bash
$(terraform output -raw scale_down_command)
```

EKS control plane stays running (~$2.40/day) but EC2 costs drop to $0.

### Resume

```bash
$(terraform output -raw scale_up_command)
```

Nodes come back in ~3 minutes.

### Full Teardown

```bash
terraform destroy
```

Destroys everything. Takes ~15 minutes. No ongoing charges after completion.

---

## Estimated Costs

| Usage Pattern | Monthly Cost |
|---|---|
| Always running (24/7) | ~$270 |
| Keep EKS, scale nodes on 20 hrs/week | ~$95 |
| Full destroy/recreate, 15 hrs/week | ~$17 |

---

## Configuration

All settings are in `terraform.tfvars`. Key toggles:

| Variable | Default | Purpose |
|---|---|---|
| `enable_nat_gateway` | `true` | Set `false` if you only need intra-VPC traffic |
| `enable_elasticache` | `false` | Set `true` when ready to add Redis |
| `node_min_size` | `0` | Allows scaling to zero between sessions |
| `node_desired_size` | `2` | Number of nodes when active |
| `rds_multi_az` | `false` | Set `true` to practice HA database patterns |

---

## Troubleshooting

| Issue | Solution |
|---|---|
| `terraform apply` times out on EKS | EKS takes 15-25 min to create. Wait or check CloudFormation console. |
| `kubectl` can't connect | Run: `aws eks update-kubeconfig --name k8s-training-dev-cluster --region us-east-1` |
| Pods stuck in `Pending` | Nodes may be scaled to 0. Run the scale-up command. |
| ALB not created from Ingress | Check ALB controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller` |
| `post-apply.sh` fails on Helm | Ensure Helm 3.x is installed and you have internet access for chart repos. |
