 #!/bin/bash
  set -e

  NEW_HOSTNAME="${1:?Usage: $0 <new-hostname> <static-ip> <join-command>}"
  NEW_IP="${2:?}"
  JOIN_CMD="${3:?}"  # full kubeadm join command in quotes

  # Hostname
  hostnamectl set-hostname "$NEW_HOSTNAME"
  sed -i "s/127.0.1.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts

  # Machine ID
  rm -f /etc/machine-id
  systemd-machine-id-setup

  # SSH host keys
  rm -f /etc/ssh/ssh_host_*
  ssh-keygen -A
  systemctl restart ssh

  # Static IP (netplan — adjust interface name as needed)
  IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')
  cat > /etc/netplan/01-netcfg.yaml <<EOF
  network:
    version: 2
    ethernets:
      $IFACE:
        addresses: [$NEW_IP/24]
        routes:
          - to: default
            via: $(ip route | awk '/default/ {print $3}')
        nameservers:
          addresses: [8.8.8.8]
  EOF
  netplan apply

  # Kubernetes
  kubeadm reset -f
