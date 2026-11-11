# Installing the host

The host is any x86_64 machine running **Ubuntu Server LTS**, headless and
reached over SSH. Everything else (VMs, cluster) is created by the repo's
scripts. The examples call it `lab-host` at `192.168.1.20` — use your own
name and address.

## 1. BIOS/UEFI

- Enable hardware virtualization: **Intel VT-x** (often "Virtualization
  Technology") or **AMD-V** ("SVM Mode"). Enable VT-d / AMD-Vi if present.
- Optional: set the machine to power on after power loss, for an always-on lab.

## 2. Install Ubuntu Server

1. Write the Ubuntu Server LTS ISO to a USB stick.
2. Install with a monitor and keyboard attached (the only time you need them):
   - Use the whole disk with LVM. Grow the root LV to the full disk if the
     installer leaves space free — VM disks live in `/var/lib/libvirt`.
   - Tick **Install OpenSSH server**, and import your public key from
     GitHub if offered.
   - Skip the featured snaps.

## 3. Fixed IP

Either reserve an address for the host in your router's DHCP (simplest), or
set it statically in netplan, e.g. `/etc/netplan/50-cloud-init.yaml`.
Replace `eno1` with your interface name (`ip link`):

```yaml
network:
  version: 2
  ethernets:
    eno1:
      dhcp4: false
      addresses: [192.168.1.20/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [192.168.1.1]
```

```bash
sudo netplan try
```

## 4. SSH from your computer

```bash
ssh-copy-id you@192.168.1.20      # if the key wasn't imported during install
```

`~/.ssh/config` on your computer:

```text
Host lab-host
  HostName 192.168.1.20
  User you
```

Then harden `/etc/ssh/sshd_config` (`PasswordAuthentication no`) and
`sudo systemctl restart ssh`.

## 5. Updates

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y unattended-upgrades git make
```

## 6. Clone and go

```bash
git clone <this repo> && cd cka-lab
make host
make check
```

Connect VS Code with Remote-SSH to `lab-host` to edit the repo there.

If you use a different SSH alias, pass it when generating the node config:
`make ssh-config JUMP=<alias>`.
