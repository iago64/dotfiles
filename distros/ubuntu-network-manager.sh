#!/usr/bin/env bash
set -Eeuo pipefail

# This is intentionally separate from the main installer because applying
# Netplan changes can interrupt the current network connection.
sudo tee /etc/netplan/01-network-manager-all.yaml >/dev/null <<'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF

sudo netplan apply
sudo systemctl restart NetworkManager
nmcli device
