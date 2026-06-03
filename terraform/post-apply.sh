#!/usr/bin/env bash
set -euo pipefail

# Post-apply script: installs Kubernetes add-ons via Helm after EKS cluster is ready.
# Usage: ./post-apply.sh
# Prerequisites: aws cli, kubectl, helm, terraform (in the terraform/ directory)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}"

echo "==> Reading Terraform outputs..."
CLUSTER_NAME=$(terraform -chdir="$TF_DIR" output -raw eks_cluster_name)
REGION=$(terraform -chdir="$TF_DIR" output -raw region)
ALB_ROLE_ARN=$(terraform -chdir="$TF_DIR" output -raw alb_controller_role_arn)
VPC_ID=$(terraform -chdir="$TF_DIR" output -raw vpc_id)

echo "==> Configuring kubectl for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

echo "==> Adding Helm repositories..."
helm repo add eks https://aws.github.io/eks-charts
helm repo add external-secrets https://charts.external-secrets.io
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

# --- Metrics Server (required for HPA) ---
echo "==> Installing metrics-server..."
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args[0]="--kubelet-preferred-address-types=InternalIP"

# --- AWS Load Balancer Controller ---
echo "==> Installing AWS Load Balancer Controller..."
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master" 2>/dev/null || true

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ALB_ROLE_ARN" \
  --set region="$REGION" \
  --set vpcId="$VPC_ID"

# --- External Secrets Operator ---
echo "==> Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true

# --- Create application namespaces ---
echo "==> Creating application namespaces..."
for NS in api-dev api-qa api-prod; do
  kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
done

# --- Create ClusterSecretStore for Secrets Manager ---
echo "==> Creating ClusterSecretStore..."
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: $REGION
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
EOF

echo ""
echo "=== Post-apply complete ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region:  $REGION"
echo ""
echo "Next steps:"
echo "  1. Verify pods:  kubectl get pods -A"
echo "  2. Build and push your app image to: $(terraform -chdir="$TF_DIR" output -raw ecr_repository_url)"
echo "  3. Deploy with:  kubectl apply -k k8s/overlays/dev"
echo ""
echo "Cost-saving commands:"
echo "  Pause:  $(terraform -chdir="$TF_DIR" output -raw scale_down_command)"
echo "  Resume: $(terraform -chdir="$TF_DIR" output -raw scale_up_command)"
