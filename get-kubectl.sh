  mkdir -p ~/.kube
  ssh root@192.168.122.213 cat /etc/kubernetes/admin.conf > ~/.kube/config
  chmod 600 ~/.kube/config

  kubectl get nodes
