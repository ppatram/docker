#!/bin/bash
set -e

POD_CIDR="10.244.0.0/16"

# 1. Clean up Flannel
ip link delete flannel.1 2>/dev/null || true
rm -rf /var/lib/cni/ /etc/cni/net.d/*
systemctl restart kubelet

# 2. Install Calico (master only)
if [ -f /etc/kubernetes/admin.conf ]; then
  export KUBECONFIG=/etc/kubernetes/admin.conf

  kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml --ignore-not-found

  kubectl apply --server-side -f \
    https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml

  curl -s https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/custom-resources.yaml \
    | sed "s|192.168.0.0/16|$POD_CIDR|" \
    | kubectl apply -f -

  echo "Waiting for Calico pods..."
  kubectl rollout status daemonset/calico-node -n calico-system --timeout=120s
  kubectl get nodes
else
  echo "Worker node cleaned up. Done."
fi
