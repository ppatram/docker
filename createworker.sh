#!/bin/bash
set -e

# Configuration
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
BASE_IMG="/var/lib/libvirt/images/master.qcow2"
DISK_DIR="/var/lib/libvirt/images"
RAM=2048
VCPUS=2
DISK_SIZE=20G
SSH_PUB_KEY="${SSH_PUB_KEY:-$(cat ~/.ssh/id_rsa.pub 2>/dev/null || cat ~/.ssh/id_ed25519.pub 2>/dev/null || echo '')}"

VMS=("worker2")

for VM in "${VMS[@]}"; do
  echo "Creating VM: $VM"

  DISK="${DISK_DIR}/${VM}.qcow2"
  CIDATA="${DISK_DIR}/${VM}-cidata.img"

  # Create disk from base image

  # Generate cloud-init config
  TMPDIR=$(mktemp -d)
  cat > "${TMPDIR}/user-data" <<EOF
#cloud-config
hostname: ${VM}
users:
  - name: root
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBX/sK1MNdF0NEqybbh+z6WrN0txvvFPTHUW6NfRmYvH owner@DESKTOP-INMDB24
  - name: kube
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${SSH_PUB_KEY}
package_update: true
packages:
  - openssh-server
  - qemu-guest-agent
runcmd:
  - sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  - systemctl enable ssh
  - systemctl restart ssh
  -  echo "root:wally" | chpasswd
EOF

  cat > "${TMPDIR}/meta-data" <<EOF
instance-id: ${VM}
local-hostname: ${VM}
EOF

  # Create cloud-init ISO
  cloud-localds "$CIDATA" "${TMPDIR}/user-data" "${TMPDIR}/meta-data" 2>/dev/null || \
    genisoimage -output "$CIDATA" -volid cidata -joliet -rock "${TMPDIR}/user-data" "${TMPDIR}/meta-data" 2>/dev/null || \
    sudo mkisofs -output "$CIDATA" -volid cidata -joliet -rock "${TMPDIR}/user-data" "${TMPDIR}/meta-data"

  rm -rf "$TMPDIR"

  # Create VM
  sudo virt-install \
    --name "$VM" \
    --ram "$RAM" \
    --vcpus "$VCPUS" \
    --disk path="$DISK",format=qcow2 \
    --disk path="$CIDATA",device=cdrom \
    --os-variant ubuntu20.04 \
    --network network=default \
    --import \
    --graphics none \
    --noautoconsole

  echo "$VM created."
done

echo ""
echo "All VMs created. Wait ~60s for cloud-init to finish."
echo "Get IPs: virsh net-dhcp-leases default"
echo "SSH: ssh kube@<ip>"
