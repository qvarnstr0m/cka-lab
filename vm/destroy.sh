#!/usr/bin/env bash
# Destroy VMs, their snapshots and disks.
# Usage: vm/destroy.sh [node...]   (default: all nodes)
source "$(dirname "$0")/../lib/common.sh"

export LIBVIRT_DEFAULT_URI=qemu:///system

targets=("$@")
[[ ${#targets[@]} -gt 0 ]] || targets=("${NODES[@]}")

for name in "${targets[@]}"; do
  if virsh dominfo "${name}" &>/dev/null; then
    log "Destroying ${name}"
    virsh destroy "${name}" 2>/dev/null || true
    virsh undefine "${name}" --snapshots-metadata --nvram 2>/dev/null \
      || virsh undefine "${name}" --snapshots-metadata
  fi
  sudo rm -f "${IMAGE_DIR}/${name}.qcow2" "${IMAGE_DIR}/${name}-seed.iso"
  ssh-keygen -f "${LAB_KNOWN_HOSTS}" -R "$(node_ip "${name}")" &>/dev/null || true
done
