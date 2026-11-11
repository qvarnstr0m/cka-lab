# Building the cluster by hand

The exam is done by hand, so practise this at least a few times instead of
`make cluster`. Start from fresh VMs (`make vms`, then `make snapshot
NAME=vms` so you can return here).

Versions below assume `K8S_MINOR=1.35`; use what's in `config/versions.env`.
The official reference is the kubeadm page "Creating a cluster with kubeadm"
on kubernetes.io — learn to find things there quickly, it's allowed in the exam.

## On every node

### Swap, kernel modules, sysctl

```bash
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

### containerd

```bash
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
```

### kubeadm, kubelet, kubectl

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet
```

## On the control plane (`cp`)

```bash
sudo kubeadm init \
  --apiserver-advertise-address=192.168.150.10 \
  --control-plane-endpoint=cp:6443 \
  --pod-network-cidr=10.244.0.0/16

mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown "$(id -u):$(id -g)" ~/.kube/config
kubectl get nodes          # NotReady until a CNI is installed
```

### Calico

```bash
V=v3.30.3
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$V/manifests/operator-crds.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$V/manifests/tigera-operator.yaml
curl -fsSLO https://raw.githubusercontent.com/projectcalico/calico/$V/manifests/custom-resources.yaml
sed -i 's#192.168.0.0/16#10.244.0.0/16#' custom-resources.yaml   # must match --pod-network-cidr
kubectl create -f custom-resources.yaml
```

## On each worker

```bash
# on cp:
kubeadm token create --print-join-command
# on the worker, paste the output with sudo:
sudo kubeadm join cp:6443 --token ... --discovery-token-ca-cert-hash sha256:...
```

## Check

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl run test --image=nginx && kubectl get pod test -o wide
```

Snapshot it: `make snapshot NAME=clean`.
