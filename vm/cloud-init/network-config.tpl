network:
  version: 2
  ethernets:
    primary:
      match:
        macaddress: "${MAC}"
      set-name: enp1s0
      dhcp4: true
