
#!/bin/bash
# (c) J~Net 2026
#
# ./setup.sh
#
#

b_user="$USER"
b_group="wireshark"
project_dir="$HOME/Documents/Scripts/BASH/extract-file-from-pcap"

# Make scripts executable.
sudo chmod +x "$project_dir"/*.sh

# Install dependencies.
sudo apt install -y tshark python3 curl login

# Configure for packet capture.
sudo dpkg-reconfigure wireshark-common

# Add user to Wireshark group.
sudo usermod -aG "$b_group" "$b_user"

# Configure dumpcap permissions.
dumpcap_path="$(command -v dumpcap)"

if [[ -n "$dumpcap_path" ]]; then
    sudo chgrp "$b_group" "$dumpcap_path"
    sudo chmod 750 "$dumpcap_path"
    sudo setcap cap_net_raw,cap_net_admin+eip "$dumpcap_path"
else
    echo "[ERROR] dumpcap not found."
    exit 1
fi

# Set project ownership.
sudo chown -R "$b_user:$b_user" "$project_dir"

# Verify configuration.
echo
echo "========== SETUP COMPLETE =========="
echo "[OK] Dependencies installed."
echo "[OK] Wireshark group configured."
echo "[OK] dumpcap capabilities configured."
echo "[OK] Project ownership configured."
echo "[OK] Scripts made executable."

echo
echo "[INFO] dumpcap capabilities:"
getcap "$dumpcap_path"

echo
echo "[IMPORTANT] Log out and back in for group changes to take effect."
echo


