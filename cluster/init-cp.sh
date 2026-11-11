#!/usr/bin/env bash
# Runs on the host. Initialises the control plane with kubeadm over SSH,
# sets up kubectl for the VM user and copies the kubeconfig to .lab/.
source "$(dirname "$0")/../lib/common.sh"

cp_node="$(control_plane)"
cp_ip="$(node_ip "${cp_node}")"

if node_ssh "${cp_node}" test -f /etc/kubernetes/admin.conf; then
  warn "${cp_node} is already initialised, skipping kubeadm init"
else
  log "kubeadm init on ${cp_node} (${cp_ip})"
  node_ssh "${cp_node}" sudo kubeadm init \
    --apiserver-advertise-address="${cp_ip}" \
    --control-plane-endpoint="${cp_node}:6443" \
    --pod-network-cidr="${POD_CIDR}" \
    --service-cidr="${SERVICE_CIDR}" \
    --node-name="${cp_node}"
fi

log "Configuring kubectl for ${VM_USER} on ${cp_node}"
# shellcheck disable=SC2016 # expands on the node
node_ssh "${cp_node}" 'mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown "$(id -u):$(id -g)" ~/.kube/config'

node_ssh "${cp_node}" cat .kube/config > "${REPO_ROOT}/.lab/kubeconfig"
chmod 600 "${REPO_ROOT}/.lab/kubeconfig"
log "Kubeconfig saved to .lab/kubeconfig (server is ${cp_node}:6443, reachable from the host via /etc/hosts or the VMs)"
