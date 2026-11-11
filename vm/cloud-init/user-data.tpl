#cloud-config
hostname: ${HOSTNAME}
fqdn: ${HOSTNAME}.${NET_NAME}.lab
manage_etc_hosts: false

users:
  - name: ${VM_USER}
    groups: [sudo]
    shell: /bin/bash
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: true
    ssh_authorized_keys:
      - ${SSH_PUBKEY}

ssh_pwauth: false
package_update: true
packages:
  - qemu-guest-agent
  - vim
  - bash-completion
  - jq

write_files:
  - path: /etc/hosts
    content: |
      127.0.0.1 localhost
${HOSTS_ENTRIES}

runcmd:
  - systemctl enable --now qemu-guest-agent
