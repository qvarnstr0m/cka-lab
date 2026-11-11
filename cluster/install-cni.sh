#!/usr/bin/env bash
# Runs on the host. Installs Calico via the Tigera operator with the pod CIDR
# from config/cluster.env, then waits for the nodes to become Ready.
source "$(dirname "$0")/../lib/common.sh"

base="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests"

log "Installing Calico ${CALICO_VERSION}"
cp_kubectl create -f "${base}/operator-crds.yaml" 2>/dev/null || true
cp_kubectl create -f "${base}/tigera-operator.yaml" 2>/dev/null \
  || cp_kubectl apply --server-side -f "${base}/tigera-operator.yaml"

curl -fsSL "${base}/custom-resources.yaml" \
  | sed "s#cidr: 192.168.0.0/16#cidr: ${POD_CIDR}#" \
  | node_ssh "$(control_plane)" kubectl apply -f -

log "Waiting for nodes to become Ready"
cp_kubectl wait --for=condition=Ready nodes --all --timeout=600s
cp_kubectl get nodes -o wide
