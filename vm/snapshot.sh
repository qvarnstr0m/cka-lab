#!/usr/bin/env bash
# Save, restore, list or delete snapshots of all nodes at once.
# Usage: vm/snapshot.sh save|restore|delete <name>
#        vm/snapshot.sh list
source "$(dirname "$0")/../lib/common.sh"

export LIBVIRT_DEFAULT_URI=qemu:///system

action="${1:-}"; snap="${2:-}"

case "${action}" in
  save)
    [[ -n "${snap}" ]] || die "usage: $0 save <name>"
    for n in "${NODES[@]}"; do
      log "Snapshot ${n} -> ${snap}"
      virsh snapshot-create-as "${n}" "${snap}" --atomic >/dev/null
    done
    ;;
  restore)
    [[ -n "${snap}" ]] || die "usage: $0 restore <name>"
    for n in "${NODES[@]}"; do
      log "Revert ${n} -> ${snap}"
      virsh snapshot-revert "${n}" "${snap}" --running
    done
    ;;
  delete)
    [[ -n "${snap}" ]] || die "usage: $0 delete <name>"
    for n in "${NODES[@]}"; do virsh snapshot-delete "${n}" "${snap}"; done
    ;;
  list)
    for n in "${NODES[@]}"; do echo "## ${n}"; virsh snapshot-list "${n}" --name; done
    ;;
  *)
    die "usage: $0 save|restore|delete <name> | list"
    ;;
esac
