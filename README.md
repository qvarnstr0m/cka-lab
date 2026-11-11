# cka-lab

A home lab for the **Certified Kubernetes Administrator (CKA)** exam: a real
multi-node kubeadm cluster in KVM virtual machines on a single machine, plus
setup scripts and exam-style exercises.

Local tools like kind, k3d and minikube are great for daily `kubectl`
practice, but they can't cover the parts of the CKA that need real nodes:
building a cluster with kubeadm, upgrading it, etcd backup/restore, and
troubleshooting kubelet and static pods over SSH. This lab can.

## Requirements

- An **x86_64** machine with hardware virtualization (Intel VT-x or AMD-V)
  enabled, running on bare metal — or a VM with nested virtualization
- **16 GB RAM** minimum (32 GB recommended) and ~100 GB free disk
- **Ubuntu Server LTS** on the host, installed with the OpenSSH server
  ([docs/host-install.md](docs/host-install.md))

The cluster VMs run Ubuntu Server LTS cloud images under libvirt/KVM. VM sizes
are set in `config/cluster.env`; lower them to fit a smaller machine. A Mac
can't be the host (no KVM), but works fine as the computer you connect from.

**Reference setup:** Lenovo ThinkCentre Tiny, 32 GB RAM, headless — small,
quiet and low-power, with room for 3–5 VMs.

## Quick start

On the host (over SSH):

```bash
git clone <this repo> && cd cka-lab
make host                    # once: KVM, libvirt, lab network (log out/in afterwards)
make check
make vms                     # creates cp, worker1, worker2
make cluster                 # kubeadm + Calico
make snapshot NAME=clean

make exercise E=troubleshooting/broken-kubelet
make verify   E=troubleshooting/broken-kubelet
make restore  NAME=clean
```

Run `make` for all targets.

From your own computer, add the SSH config so you can reach the nodes through
the host with `ProxyJump`:

```bash
ssh lab-host 'cd cka-lab && make ssh-config JUMP=lab-host' >> ~/.ssh/config
ssh cp
```

Editing works well with VS Code Remote-SSH connected to the host. To work on
the lab away from home, see [docs/remote-access.md](docs/remote-access.md)
(Tailscale).

## Layout

| Path | What |
| --- | --- |
| `config/` | Pinned versions (`versions.env`) and cluster layout (`cluster.env`) |
| `host/` | Host setup: packages, libvirt network, optional bridge, checks |
| `vm/` | VM lifecycle: create from cloud image, destroy, snapshots, SSH config |
| `cluster/` | kubeadm: node prep, init, join, Calico, reset |
| `exercises/` | Exam-style tasks with setup/verify scripts ([index](exercises/README.md)) |
| `docs/` | Host install, manual cluster build, exam tips, curriculum map |
| `lib/` | Shared bash helpers |

## Network

| Node | IP | Role |
| --- | --- | --- |
| cp | 192.168.150.10 | control plane |
| worker1 | 192.168.150.11 | worker |
| worker2 | 192.168.150.12 | worker |

The nodes sit on a libvirt NAT network with fixed DHCP reservations. Pods use
`10.244.0.0/16`, Services `10.96.0.0/12`. Change them in `config/cluster.env`.

## Design principles

- **Pinned versions in one place** — `config/versions.env`.
- **Snapshots as the backbone** — break things freely, then `make restore`.
- **Self-contained exercises** — each one sets up its own scenario.
- **Manual install guide next to the scripts** — the exam is done by hand
  ([docs/manual-install.md](docs/manual-install.md)).
- **No secrets in git** — kubeconfigs, tokens and keys live in `.lab/`
  (ignored).
- **Plain bash plus a Makefile** — low barrier, easy to read.

## Exam notes

Buying the CKA includes two killer.sh simulator sessions (36 hours each, same
questions in both) — harder than the real exam, best saved for the final
week. See [docs/exam-tips.md](docs/exam-tips.md).

## License

[MIT](LICENSE)
