
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

# Set Perms for tshark

PROJECT="/home/jay/Documents/Scripts/BASH/extract-file-from-pcap"
EXPORT="$PROJECT/export"
PROFILE="/etc/apparmor.d/tshark"
LOCAL="/etc/apparmor.d/local/tshark"

echo "========== FIXING EXPORT PERMISSIONS =========="

sudo mkdir -p "$EXPORT"
sudo chown -R jay:jay "$EXPORT"
chmod 755 "$EXPORT"

echo
echo "========== APPARMOR CONFIGURATION =========="

if [ -f "$PROFILE" ]; then
    sudo mkdir -p /etc/apparmor.d/local
    sudo touch "$LOCAL"

    RULE1="owner $EXPORT/ rw,"
    RULE2="owner $EXPORT/** rw,"

    grep -Fqx "$RULE1" "$LOCAL" || echo "$RULE1" | sudo tee -a "$LOCAL" >/dev/null
    grep -Fqx "$RULE2" "$LOCAL" || echo "$RULE2" | sudo tee -a "$LOCAL" >/dev/null

    sudo apparmor_parser -r "$PROFILE" || exit 1

    echo "[OK] AppArmor profile updated."
else
    echo "[WARNING] TShark AppArmor profile not found."
fi

echo
echo "========== PERMISSIONS =========="
ls -ld "$EXPORT"
echo
echo "========== COMPLETE =========="
