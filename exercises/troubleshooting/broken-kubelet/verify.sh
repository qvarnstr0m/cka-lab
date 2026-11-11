#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/exercise.sh"

check "kubelet is running on worker1"         node_ssh worker1 systemctl is-active --quiet kubelet
check "kubelet is enabled on worker1"         node_ssh worker1 systemctl is-enabled --quiet kubelet
check "kubelet runs the installed binary"     node_ssh worker1 "systemctl show kubelet -p ExecStart | grep -q /usr/bin/kubelet"
check "worker1 is Ready"                      node_ready worker1
finish
