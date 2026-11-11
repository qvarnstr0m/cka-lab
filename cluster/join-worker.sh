#!/usr/bin/env bash
# Runs on the host. Joins worker nodes to the cluster.
# Usage: cluster/join-worker.sh [worker...]   (default: all workers)
source "$(dirname "$0")/../lib/common.sh"

cp_node="$(control_plane)"
targets=("$@")
# shellcheck disable=SC2207
[[ ${#targets[@]} -gt 0 ]] || targets=($(workers))

join_cmd="$(node_ssh "${cp_node}" sudo kubeadm token create --print-join-command)"

for w in "${targets[@]}"; do
  if node_ssh "${w}" test -f /etc/kubernetes/kubelet.conf; then
    warn "${w} has already joined, skipping"
    continue
  fi
  log "Joining ${w}"
  # shellcheck disable=SC2086
  node_ssh "${w}" sudo ${join_cmd} --node-name="${w}"
done
