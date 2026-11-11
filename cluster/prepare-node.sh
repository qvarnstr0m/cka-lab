#!/usr/bin/env bash
# Runs ON A NODE as root (piped over SSH by the Makefile / node_run_script).
# Prepares the node for kubeadm: swap off, kernel modules, sysctl,
# containerd, and kubeadm/kubelet/kubectl from pkgs.k8s.io.
# Env: K8S_MINOR (e.g. 1.35), CONTAINERD_VERSION (optional)
set -euo pipefail

: "${K8S_MINOR:?K8S_MINOR must be set}"
export DEBIAN_FRONTEND=noninteractive

echo "==> [$(hostname)] swap off"
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

echo "==> [$(hostname)] kernel modules and sysctl"
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null

echo "==> [$(hostname)] containerd"
apt-get update -q
if [[ -n "${CONTAINERD_VERSION:-}" ]]; then
  apt-get install -y -q "containerd=${CONTAINERD_VERSION}"
else
  apt-get install -y -q containerd
fi
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
# kubelet uses the systemd cgroup driver by default
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

echo "==> [$(hostname)] kubeadm, kubelet, kubectl v${K8S_MINOR}"
apt-get install -y -q apt-transport-https ca-certificates curl gpg
install -d -m 0755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/Release.key" \
  | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list
apt-get update -q
apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true
apt-get install -y -q kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

echo "==> [$(hostname)] ready: $(kubeadm version -o short)"
