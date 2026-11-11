#!/usr/bin/env bash
# Breaks the kubelet on worker1: a systemd drop-in points ExecStart at a
# binary that doesn't exist, and the service is disabled.
source "$(dirname "$0")/../../lib/exercise.sh"

require_cluster

node_ssh worker1 'sudo bash -s' <<'EOF'
mkdir -p /etc/systemd/system/kubelet.service.d
cat > /etc/systemd/system/kubelet.service.d/20-local.conf <<'CONF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
CONF
systemctl daemon-reload
systemctl disable kubelet >/dev/null 2>&1
systemctl restart kubelet || true
EOF

log "worker1 will turn NotReady within about a minute."
