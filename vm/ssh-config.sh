#!/usr/bin/env bash
# Print an ~/.ssh/config block for reaching the VMs from your own computer
# through the host with ProxyJump.
# Usage: vm/ssh-config.sh <host-alias-or-ip> [host-user]  >> ~/.ssh/config
source "$(dirname "$0")/../lib/common.sh"

jump="${1:-tiny}"
jump_user="${2:-${USER}}"

cat <<EOF
# --- cka-lab ---
Host ${jump}
  User ${jump_user}

EOF

for i in "${!NODES[@]}"; do
  cat <<EOF
Host ${NODES[$i]}
  HostName ${NODE_IPS[$i]}
  User ${VM_USER}
  ProxyJump ${jump}
  StrictHostKeyChecking accept-new
  UserKnownHostsFile ~/.ssh/known_hosts.cka-lab

EOF
done
echo "# --- end cka-lab ---"
