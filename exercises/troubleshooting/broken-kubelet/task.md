# Broken kubelet

**Domain:** Troubleshooting · **Weight:** medium · **Time:** ~8 min

Context: `ssh cp`

Node `worker1` is reporting `NotReady`.

1. Find out why and fix the problem so that `worker1` becomes `Ready`.
2. Make sure the fix survives a reboot of `worker1`.

Do not delete or re-join the node.

When done: `make verify E=troubleshooting/broken-kubelet`
