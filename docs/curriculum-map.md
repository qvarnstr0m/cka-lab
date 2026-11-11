# Curriculum map

Which exercises cover which CKA domains. Weights are from the CNCF curriculum —
check the current version on the CNCF curriculum repo, it changes over time.

| Domain | Weight | Exercises |
| --- | --- | --- |
| Troubleshooting | 30% | [broken-kubelet](../exercises/troubleshooting/broken-kubelet/task.md), missing-static-pod, node-not-ready |
| Cluster Architecture, Installation & Configuration | 25% | upgrade-minor, etcd-backup-restore, rbac-user-access, helm-install, manual install ([guide](manual-install.md)) |
| Services & Networking | 20% | network-policy, gateway-api |
| Workloads & Scheduling | 15% | taints-tolerations, node-affinity |
| Storage | 10% | pv-pvc-storageclass |

Topics with no exercise yet (good candidates): Kustomize, CRDs/operators,
HPA, PriorityClass, CoreDNS troubleshooting, Ingress, ConfigMaps/Secrets,
resource limits/quotas, sidecar containers.
