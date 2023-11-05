#!/bin/bash

# Check if the script is run with sudo privileges, if not, re-execute with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo. Prompting for sudo password..."
    sudo bash "$0" "$@"
    exit $?
fi

# Change the script file format to Unix if it was edited on Windows
dos2unix "$0"

# Store the current adapter name
adapter=$(iw dev | grep Interface | awk '{print $2}')

# Change adapter to monitor mode
echo "[*] Putting $adapter into monitor mode..."
ip link set $adapter down
iw $adapter set monitor control
ip link set $adapter up

# Perform operations in monitor mode here (e.g., capturing packets)

# Change adapter back to managed mode
echo "[*] Putting $adapter back into managed mode..."
ip link set $adapter down
iw $adapter set type managed
ip link set $adapter up

# Connect to a Wi-Fi network (replace 'YOUR_SSID' and 'YOUR_PASSWORD' with your network SSID and password)
echo "[*] Connecting $adapter to Wi-Fi network..."
iw dev $adapter connect -w YOUR_SSID
wpa_supplicant -B -i $adapter -c <(wpa_passphrase "YOUR_SSID" "YOUR_PASSWORD")
dhclient $adapter

echo "[*] Adapter $adapter is now in managed mode and connected to the Wi-Fi network."

# Restart Network Manager service
echo "[*] Restarting Network Manager service..."
sudo systemctl restart NetworkManager

echo "[*] Network Manager service restarted."
