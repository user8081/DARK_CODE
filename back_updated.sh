#!/bin/bash

# Function to check if the script is run with sudo privileges
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run with sudo. Exiting..."
        exit 1
    fi
}

# Function to change the script file format to Unix if it was edited on Windows
convert_to_unix() {
    dos2unix "$0"
}

# Function to put the adapter into monitor mode
put_adapter_into_monitor_mode() {
    echo "[*] Putting $adapter into monitor mode..."
    ip link set "$adapter" down
    iw "$adapter" set monitor control
    ip link set "$adapter" up
}

# Function to perform operations in monitor mode
perform_operations_in_monitor_mode() {
    # Add your code here for operations in monitor mode
    echo "[*] Performing operations in monitor mode..."
}

# Function to put the adapter back into managed mode
put_adapter_into_managed_mode() {
    echo "[*] Putting $adapter back into managed mode..."
    ip link set "$adapter" down
    iw "$adapter" set type managed
    ip link set "$adapter" up
}

# Function to connect to a Wi-Fi network
connect_to_wifi() {
    # Check if iw and wpa_supplicant are installed
    if ! command -v iw &> /dev/null || ! command -v wpa_supplicant &> /dev/null; then
        echo "Error: 'iw' or 'wpa_supplicant' not found. Install them with 'sudo apt-get install wireless-tools wpasupplicant'."
        exit 1
    fi

    # Display saved Wi-Fi profiles
    saved_profiles=$(ls /etc/NetworkManager/system-connections)
    echo "[?] Choose a Wi-Fi network to connect:"
    select profile in $saved_profiles; do
        if [[ -n "$profile" ]]; then
            echo "[*] Connecting $adapter to Wi-Fi network: $profile"
            nmcli connection up "$profile" iface "$adapter"
            break
        else
            echo "Invalid selection. Please choose a valid option."
        fi
    done
}

# Function to restart Network Manager service
restart_network_manager() {
    echo "[*] Restarting Network Manager service..."
    systemctl restart NetworkManager
    echo "[*] Network Manager service restarted."
}

main() {
    check_sudo
    convert_to_unix

    # Store the current adapter name
    adapter=$(iw dev | grep Interface | awk '{print $2}')

    put_adapter_into_monitor_mode
    perform_operations_in_monitor_mode
    put_adapter_into_managed_mode
    connect_to_wifi
    restart_network_manager
}

# Execute the main function
main
