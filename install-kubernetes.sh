#!/bin/bash
set -ex

MASTER=$(virsh domifaddr master | awk '/ipv4/{print $4}' | cut -d/ -f1)
NODE1=$(virsh domifaddr node1  | awk '/ipv4/{print $4}' | cut -d/ -f1)
NODE2=$(virsh domifaddr node2  | awk '/ipv4/{print $4}' | cut -d/ -f1)

SSH="ssh -o StrictHostKeyChecking=no root"
K8S_VERSION="1.30"
POD_CIDR="192.168.0.0/16"  # calico default

echo "Master: $MASTER  Nodes: $NODE1 $NODE2"

# Common setup for all nodes
common_setup() {
  local ip=$1
  $SSH@$ip bash <<'ENDSSH'
set -e
# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Load kernel modules
modprobe overlay
modprobe br_netfilter
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Install containerd
apt-get update -qq
apt-get install -y -qq containerd apt-transport-https curl

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd

# Install kubeadm/kubelet/kubectl
mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --batch --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
apt-get update -qq
apt-get install -y -qq kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet
ENDSSH
}

echo "==> Setting up all nodes..."
for ip in $MASTER $NODE1 $NODE2; do
  echo "  -> $ip"
  common_setup $ip
done

echo "==> Initializing master..."
$SSH@$MASTER bash <<ENDSSH
set -e
kubeadm init --pod-network-cidr=$POD_CIDR --apiserver-advertise-address=$MASTER

export KUBECONFIG=/etc/kubernetes/admin.conf

# calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/custom-resources.yaml


# Wait for API server to be ready
echo "Waiting for API server..."
until kubectl get nodes &>/dev/null; do sleep 3; done

# Install Flannel CNI
#kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
ENDSSH

echo "==> Getting join command..."
JOIN_CMD=$($SSH@$MASTER kubeadm token create --print-join-command)

echo "==> Joining worker nodes..."
for ip in $NODE1 $NODE2; do
  echo "  -> $ip"
  $SSH@$ip $JOIN_CMD
done

echo ""
echo "Done! Check cluster:"
echo "  ssh root@$MASTER kubectl get nodes"
