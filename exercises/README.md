# Exercises

Self-contained scenarios grouped by CKA curriculum domain. Each one starts
from a clean snapshot, so it's safe to break things.

## Workflow

```bash
make restore  NAME=clean
make exercise E=troubleshooting/broken-kubelet   # sets up the scenario, prints the task
# ... solve it over SSH, by hand, like in the exam ...
make verify   E=troubleshooting/broken-kubelet
make solution E=troubleshooting/broken-kubelet   # if stuck
```

## Format

```text
<domain>/<exercise>/
├── task.md       # the task, written in exam style
├── setup.sh      # creates or breaks the scenario (runs on the host)
├── verify.sh     # checks the result, exits 0 when solved
└── solution.md   # one way to solve it, plus takeaways
```

`setup.sh` and `verify.sh` source [`lib/exercise.sh`](lib/exercise.sh), which
provides `node_ssh`, `cp_kubectl`, `check`, `finish`, `node_ready` and
`wait_for_pod`.

Write tasks yourself — don't reproduce killer.sh or real exam questions.

## Index

See [docs/curriculum-map.md](../docs/curriculum-map.md) for domain coverage.

| Exercise | Domain | Status |
| --- | --- | --- |
| [troubleshooting/broken-kubelet](troubleshooting/broken-kubelet/task.md) | Troubleshooting | ready |
| troubleshooting/missing-static-pod | Troubleshooting | planned |
| troubleshooting/node-not-ready | Troubleshooting | planned |
| cluster-architecture/upgrade-minor | Cluster Architecture | planned (needs `make cluster-prev`) |
| cluster-architecture/etcd-backup-restore | Cluster Architecture | planned |
| cluster-architecture/rbac-user-access | Cluster Architecture | planned |
| cluster-architecture/helm-install | Cluster Architecture | planned |
| workloads-scheduling/taints-tolerations | Workloads & Scheduling | planned |
| workloads-scheduling/node-affinity | Workloads & Scheduling | planned |
| services-networking/network-policy | Services & Networking | planned |
| services-networking/gateway-api | Services & Networking | planned |
| storage/pv-pvc-storageclass | Storage | planned |
