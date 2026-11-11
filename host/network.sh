#!/usr/bin/env bash
# Create (or recreate) the libvirt NAT network with fixed DHCP reservations.
source "$(dirname "$0")/../lib/common.sh"

export LIBVIRT_DEFAULT_URI=qemu:///system

hosts=""
for i in "${!NODES[@]}"; do
  hosts+="      <host mac='${NODE_MACS[$i]}' name='${NODES[$i]}' ip='${NODE_IPS[$i]}'/>"$'\n'
done

xml="$(mktemp)"
trap 'rm -f "${xml}"' EXIT
cat > "${xml}" <<EOF
<network>
  <name>${NET_NAME}</name>
  <forward mode='nat'/>
  <bridge name='${NET_BRIDGE}' stp='on' delay='0'/>
  <domain name='${NET_NAME}.lab' localOnly='yes'/>
  <ip address='${NET_GATEWAY}' netmask='255.255.255.0'>
    <dhcp>
      <range start='${NET_DHCP_START}' end='${NET_DHCP_END}'/>
${hosts}    </dhcp>
  </ip>
</network>
EOF

if virsh net-info "${NET_NAME}" &>/dev/null; then
  log "Network ${NET_NAME} exists, redefining"
  virsh net-destroy "${NET_NAME}" 2>/dev/null || true
  virsh net-undefine "${NET_NAME}"
fi

virsh net-define "${xml}"
virsh net-autostart "${NET_NAME}"
virsh net-start "${NET_NAME}"
log "Network ${NET_NAME} is up on ${NET_GATEWAY}"
