# Remote access with Tailscale

By default the lab host is only reachable from your home network. Tailscale
puts the host and your other computers on a private network, so
`ssh lab-host` (and VS Code Remote-SSH) works from anywhere. It needs no open
ports on your router, and it gets through most NAT and corporate firewalls.

Once you can reach the host, the existing `ProxyJump` config takes you on to
`cp`, `worker1` and `worker2` unchanged.

> Before installing Tailscale or keeping lab SSH keys on a work laptop, check
> your employer's policy. A personal laptop avoids the question.

## 1. On the lab host

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Open the login URL it prints and sign in. Then check the address:

```bash
tailscale status
tailscale ip -4
```

In the Tailscale admin console (Machines → the host → ⋯):

- **Disable key expiry.** Otherwise the host drops off the network every
  180 days until you log it in again, which you can't do from work.
- Optionally rename the machine to `lab-host`.

## 2. On the computer you connect from

Install Tailscale from <https://tailscale.com/download> and sign in with the
same account. Check that you can see the host:

```bash
tailscale status
ping lab-host            # MagicDNS name, works if MagicDNS is on (default)
```

## 3. Point the SSH alias at the Tailscale name

In `~/.ssh/config` on your computer, change the host's `HostName` from its
LAN IP to its Tailscale name:

```text
Host lab-host
  HostName lab-host.<your-tailnet>.ts.net   # or the 100.x.y.z address
  User you
```

The full name is shown in the admin console under the machine (or by
`tailscale status` on the host). The node entries from `make ssh-config`
already use `ProxyJump lab-host`, so nothing else needs to change:

```bash
ssh lab-host
ssh cp
```

This also works at home, since Tailscale connects directly over the LAN when
it can.

## Optional: reach the VMs directly (subnet router)

ProxyJump is enough for SSH. If you also want to reach the node IPs directly
from your computer, for example to run `kubectl` locally against
`192.168.150.10:6443`, let the host advertise the libvirt network:

```bash
# on the lab host
sudo tailscale set --advertise-routes=192.168.150.0/24
```

Approve the route in the admin console (Machines → the host → Edit route
settings). Linux clients also need `sudo tailscale set --accept-routes`;
macOS and Windows clients accept routes by default.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `ssh lab-host` times out | `tailscale status` on both ends. Is the host online? Is it powered on? |
| The host shows as offline after months | Key expired. Disable key expiry (step 1). |
| Name doesn't resolve | Use the `100.x.y.z` IP, or enable MagicDNS in the admin console (DNS tab). |
| Slow connection | `tailscale ping lab-host` shows whether the link is direct or relayed (DERP). Relayed still works, just slower. |
