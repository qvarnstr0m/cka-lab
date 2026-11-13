#!/usr/bin/env bash
# Sanity checks for the host: KVM, libvirt, memory and disk.
source "$(dirname "$0")/../lib/common.sh"

fail=0
check() { if "$@"; then echo "  ok   $desc"; else echo "  FAIL $desc"; fail=1; fi; }

desc="/dev/kvm exists";            check test -e /dev/kvm
desc="kvm-ok";                     check sudo kvm-ok >/dev/null
desc="libvirtd is active";         check systemctl is-active --quiet libvirtd
desc="${USER} in libvirt group";   check grep -qw libvirt <<<"$(id -nG "${USER}")"
desc="SSH key ${SSH_PUBKEY_FILE}"; check test -f "${SSH_PUBKEY_FILE}"

need_mem=$(( CP_MEMORY + WORKER_MEMORY * (${#NODES[@]} - 1) ))
free_mem=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
echo "  info memory: ${free_mem} MiB available, ${need_mem} MiB needed for VMs"
(( free_mem >= need_mem )) || { warn "not enough free memory"; fail=1; }

need_disk=$(( DISK_SIZE * ${#NODES[@]} ))
disk_dir="${IMAGE_DIR}"; [[ -d "${disk_dir}" ]] || disk_dir=/var/lib/libvirt
free_disk=$(df -BG --output=avail "${disk_dir}" | tail -1 | tr -dc '0-9')
echo "  info disk: ${free_disk} GiB free in ${disk_dir}, up to ${need_disk} GiB if disks fill"

exit "${fail}"
