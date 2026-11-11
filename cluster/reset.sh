#!/usr/bin/env bash
# Runs on the host. Tears the cluster down with kubeadm reset on every node
# (VMs and packages stay). Restoring a snapshot is usually faster.
source "$(dirname "$0")/../lib/common.sh"

for n in "${NODES[@]}"; do
  log "kubeadm reset on ${n}"
  node_ssh "${n}" 'sudo kubeadm reset -f && sudo rm -rf /etc/cni/net.d ~/.kube && sudo iptables -F && sudo iptables -t nat -F && sudo iptables -X' || warn "reset failed on ${n}"
done
rm -f "${REPO_ROOT}/.lab/kubeconfig"
