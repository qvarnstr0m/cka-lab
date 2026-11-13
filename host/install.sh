#!/usr/bin/env bash
# Install KVM/libvirt and VM tooling on the Ubuntu Server host. Run once.
source "$(dirname "$0")/../lib/common.sh"

[[ "$(id -u)" -eq 0 ]] && die "run as your normal user (sudo is used where needed)"

log "Installing packages"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients \
  virtinst cloud-image-utils cpu-checker \
  make jq curl openssh-client gettext-base

log "Adding ${USER} to libvirt and kvm groups"
sudo usermod -aG libvirt,kvm "${USER}"

log "Enabling libvirtd"
sudo systemctl enable --now libvirtd

if [[ ! -f "${SSH_PUBKEY_FILE}" ]]; then
  log "No SSH key at ${SSH_PUBKEY_FILE}, creating one for the VMs"
  ssh-keygen -t ed25519 -N '' -f "${SSH_PRIVKEY_FILE}"
fi

sudo install -d -m 0755 "${IMAGE_DIR}"

log "Done. Log out and back in (or run 'newgrp libvirt') for group membership to apply."
