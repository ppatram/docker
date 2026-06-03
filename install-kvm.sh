#!/bin/bash
set -e

# Check for VT-x/AMD-V support
if ! grep -qE '(vmx|svm)' /proc/cpuinfo; then
  echo "ERROR: CPU does not support hardware virtualization" >&2
  exit 1
fi

# Install KVM and tools
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager

# Add current user to required groups
sudo usermod -aG libvirt,kvm "$(whoami)"

# Ensure libvirtd is running
sudo systemctl enable --now libvirtd

echo "KVM installed successfully. Log out and back in for group permissions to take effect."
