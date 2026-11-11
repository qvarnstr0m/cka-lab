# Solution: Broken kubelet

```bash
kubectl get nodes                        # worker1 NotReady
kubectl describe node worker1            # "Kubelet stopped posting node status"
ssh worker1
sudo systemctl status kubelet            # failed: /usr/local/bin/kubelet not found
sudo journalctl -u kubelet -n 20
systemctl cat kubelet                    # shows every drop-in, in order
which kubelet                            # /usr/bin/kubelet
```

`/etc/systemd/system/kubelet.service.d/20-local.conf` overrides `ExecStart`
with a path that doesn't exist. Remove the drop-in (or fix the path), then
reload systemd, enable and start the service:

```bash
sudo rm /etc/systemd/system/kubelet.service.d/20-local.conf
sudo systemctl daemon-reload
sudo systemctl enable --now kubelet
exit
kubectl get nodes -w
```

## Takeaways

- `systemctl cat <unit>` shows the unit plus all drop-ins — the fastest way
  to spot an override.
- A later drop-in with an empty `ExecStart=` replaces the earlier one.
- "Survives a reboot" means `enabled`, not just `active`.
