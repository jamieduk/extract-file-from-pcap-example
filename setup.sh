#!/bin/bash
# (c) J~Net 2026
#
# ./setup.sh
#
#
#
b_user="$USER"
sudo chmod +x *.sh

sudo apt install -y tshark python3 curl

# Configure for packet capture
sudo dpkg-reconfigure wireshark-common

sudo usermod -aG wireshark $USER
sudo chown -R $b_user:$b_user "$HOME/Documents/Scripts/BASH/extract-file-from-pcap"
