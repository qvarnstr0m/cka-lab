# Exam tips

## Shell setup

The exam environment usually has `k` aliased and completion enabled already.
Check first, and only add what's missing:

```bash
alias k=kubectl
complete -o default -F __start_kubectl k
export do="--dry-run=client -o yaml"     # k create deploy web --image=nginx $do > web.yaml
export now="--force --grace-period=0"    # k delete pod x $now
```

## vim

`~/.vimrc`:

```vim
set expandtab tabstop=2 shiftwidth=2
set number
syntax on
```

Paste without auto-indent mangling: `:set paste`, paste, `:set nopaste`.

## kubectl habits

- Generate YAML instead of writing it: `k create deploy|svc|job|cronjob|role|rolebinding ... $do`.
- `k explain pod.spec.containers.securityContext --recursive` beats searching docs.
- `k get ... -o wide`, `--show-labels`, `-l app=web`, `-A`.
- `k config use-context <ctx>` — **every** task names a context; switch first.
- `k auth can-i <verb> <resource> --as=<user> -n <ns>` to check RBAC.
- `k events -n <ns> --types=Warning` for quick troubleshooting.

## Node troubleshooting

- `systemctl status kubelet`, `journalctl -u kubelet -n 50`, `systemctl cat kubelet`
- `crictl ps -a`, `crictl logs <id>` when the API server is down
- Static pods: `/etc/kubernetes/manifests/`
- Certificates: `kubeadm certs check-expiration`
- etcd: `ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert --cert --key snapshot save`

## Time

- Flag hard tasks and move on; weight matters more than order.
- Verify every answer (`k get`, `k describe`, curl from a pod) before moving on.
- Exit SSH sessions back to the base terminal before the next task.

## Practice plan

1. Daily kubectl drills (kind or this lab).
2. Build the cluster by hand a few times ([manual-install.md](manual-install.md)).
3. Work through [the exercises](../exercises/README.md), timing yourself.
4. Final week: killer.sh session 1, review, then session 2.
