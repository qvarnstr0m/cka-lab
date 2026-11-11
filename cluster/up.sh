#!/usr/bin/env bash
# Runs on the host. Builds the whole cluster: prepare all nodes, kubeadm init,
# join workers, install Calico. Override the version with K8S_MINOR=1.xx.
source "$(dirname "$0")/../lib/common.sh"

dir="$(dirname "$0")"

for n in "${NODES[@]}"; do
  log "Preparing ${n} (Kubernetes v${K8S_MINOR})"
  node_run_script "${n}" "${dir}/prepare-node.sh" \
    "K8S_MINOR=${K8S_MINOR}" "CONTAINERD_VERSION=${CONTAINERD_VERSION}"
done

"${dir}/init-cp.sh"
"${dir}/join-worker.sh"
"${dir}/install-cni.sh"

log "Cluster is up. Next: make snapshot NAME=clean"
