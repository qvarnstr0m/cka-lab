#!/usr/bin/env bash
# Create the cluster VMs from the Ubuntu cloud image with cloud-init.
# Usage: vm/create.sh [node...]   (default: all nodes in config/cluster.env)
source "$(dirname "$0")/../lib/common.sh"

export LIBVIRT_DEFAULT_URI=qemu:///system

command -v envsubst >/dev/null || die "envsubst missing (apt install gettext-base)"
[[ -f "${SSH_PUBKEY_FILE}" ]] || die "no SSH public key at ${SSH_PUBKEY_FILE}"
virsh net-info "${NET_NAME}" &>/dev/null || die "network ${NET_NAME} missing, run host/network.sh"

base_img="${IMAGE_DIR}/base-${UBUNTU_RELEASE}-${UBUNTU_ARCH}.img"
base_url="https://cloud-images.ubuntu.com/${UBUNTU_RELEASE}/current/${UBUNTU_RELEASE}-server-cloudimg-${UBUNTU_ARCH}.img"

if [[ ! -f "${base_img}" ]]; then
  log "Downloading ${UBUNTU_RELEASE} cloud image"
  sudo curl -fL --retry 3 -o "${base_img}" "${base_url}"
fi

hosts_entries=""
for i in "${!NODES[@]}"; do
  hosts_entries+="      ${NODE_IPS[$i]} ${NODES[$i]} ${NODES[$i]}.${NET_NAME}.lab"$'\n'
done

tpl_dir="$(dirname "$0")/cloud-init"
targets=("$@")
[[ ${#targets[@]} -gt 0 ]] || targets=("${NODES[@]}")

for i in "${!NODES[@]}"; do
  name="${NODES[$i]}"
  [[ " ${targets[*]} " == *" ${name} "* ]] || continue

  if virsh dominfo "${name}" &>/dev/null; then
    warn "${name} already exists, skipping (vm/destroy.sh ${name} to recreate)"
    continue
  fi

  if [[ $i -eq 0 ]]; then vcpus=${CP_VCPUS}; mem=${CP_MEMORY}
  else vcpus=${WORKER_VCPUS}; mem=${WORKER_MEMORY}; fi

  log "Creating ${name} (${NODE_IPS[$i]}, ${vcpus} vCPU, ${mem} MiB)"

  disk="${IMAGE_DIR}/${name}.qcow2"
  seed="${IMAGE_DIR}/${name}-seed.iso"
  sudo qemu-img create -q -f qcow2 -F qcow2 -b "${base_img}" "${disk}" "${DISK_SIZE}G"

  work="$(mktemp -d)"
  HOSTNAME="${name}" MAC="${NODE_MACS[$i]}" NET_NAME="${NET_NAME}" VM_USER="${VM_USER}" \
  SSH_PUBKEY="$(cat "${SSH_PUBKEY_FILE}")" HOSTS_ENTRIES="${hosts_entries%$'\n'}" \
  INSTANCE_SUFFIX="$(date +%s)" \
  bash -c '
    for f in user-data meta-data network-config; do
      envsubst < "$1/$f.tpl" > "$2/$f"
    done' _ "${tpl_dir}" "${work}"

  sudo cloud-localds --network-config="${work}/network-config" \
    "${seed}" "${work}/user-data" "${work}/meta-data"
  rm -rf "${work}"

  virt-install \
    --name "${name}" \
    --vcpus "${vcpus}" --memory "${mem}" \
    --cpu host-passthrough \
    --os-variant "${UBUNTU_OS_VARIANT}" \
    --disk "path=${disk},format=qcow2,bus=virtio" \
    --disk "path=${seed},device=cdrom" \
    --network "network=${NET_NAME},mac=${NODE_MACS[$i]},model=virtio" \
    --graphics none --console pty,target_type=serial \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --import --noautoconsole
done

for name in "${targets[@]}"; do
  log "Waiting for SSH on ${name}"
  wait_for_ssh "${name}"
  node_ssh "${name}" cloud-init status --wait >/dev/null || warn "cloud-init reported errors on ${name}"
done

log "VMs ready: ${targets[*]}"
