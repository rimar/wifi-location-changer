#!/bin/bash

# Simple shell-based configuration UI for LocationChanger
set -e

CONFIG_FILE="/usr/local/bin/locationchanger.conf"
BACKUP_FILE="/usr/local/bin/locationchanger.conf.backup"
TEMP_CONFIG_FILE="/tmp/locationchanger.conf.tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print header
print_header() {
    clear
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                    📶 Location Changer Config               │${NC}"
    echo -e "${BLUE}│              Configure Wi-Fi to Location mappings           │${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Function to get current SSID
get_current_ssid() {
    local os_version=$(sw_vers -productVersion | cut -d. -f1)
    local ssid=""
    
    # For macOS 26.0+, try multiple methods due to privacy restrictions
    if [ "$os_version" -ge "26" ]; then
        # Method 1: Try shortcuts if available (requires user to create shortcut)
        if command -v shortcuts >/dev/null 2>&1; then
            ssid=$(shortcuts run "Current Wi-Fi" 2>/dev/null | tr -d '\r' | sed 's/^\s*//;s/\s*$//')
            if [ -n "$ssid" ] && [ "$ssid" != "null" ] && [ "$ssid" != "<redacted>" ]; then
                echo "$ssid"
                return 0
            fi
        fi
        
        # Method 2: Try networksetup with different approaches
        ssid=$(networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //' | grep -v "You are not associated")
        if [ -n "$ssid" ] && [ "$ssid" != "You are not associated with an AirPort network." ]; then
            echo "$ssid"
            return 0
        fi
        
        # Method 3: Check if we can get SSID from system preferences (may require admin)
        ssid=$(defaults read /Library/Preferences/SystemConfiguration/com.apple.airport.preferences 2>/dev/null | grep -A 1 "SSID_STR" | tail -1 | sed 's/.*= "\(.*\)";/\1/' 2>/dev/null)
        if [ -n "$ssid" ] && [ "$ssid" != "<redacted>" ]; then
            echo "$ssid"
            return 0
        fi
        
        # Method 4: Try system_profiler but handle redacted case
        ssid=$(system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network/ {getline; gsub(":", ""); gsub(/^[[:space:]]*/, ""); gsub(/[[:space:]]*$/, ""); print; exit}')
        if [ -n "$ssid" ] && [ "$ssid" != "<redacted>" ]; then
            echo "$ssid"
            return 0
        fi
        
        # If all methods fail on macOS 26.0+, return a helpful message
        echo "<Unable to detect - Privacy Protected>"
    else
        # Legacy method for older macOS versions
        ssid=$(system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network/ {getline; gsub(":", ""); print; exit}' | xargs)
        echo "${ssid:-Unknown}"
    fi
}

# Function to get available locations
get_available_locations() {
    networksetup -listlocations 2>/dev/null | grep -v "^$" || echo "Automatic"
}

# Function to load existing mappings
load_mappings() {
    local mappings=()
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                mappings+=("$line")
            fi
        done < "$CONFIG_FILE"
    fi
    printf '%s\n' "${mappings[@]}"
}

# Function to save mappings
save_mappings() {
    local mappings=("$@")
    
    # Create backup
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
    fi
    
    # Write new config to temp file first
    cat > "$TEMP_CONFIG_FILE" << EOF
# LocationChanger Configuration
# Format: location_name "WiFi SSID"
# Lines starting with # are comments

EOF
    
    for mapping in "${mappings[@]}"; do
        if [[ -n "$mapping" ]]; then
            echo "$mapping" >> "$TEMP_CONFIG_FILE"
        fi
    done
    
    # Move temp file to final location with sudo if needed
    if [[ -w "$(dirname "$CONFIG_FILE")" ]]; then
        mv "$TEMP_CONFIG_FILE" "$CONFIG_FILE"
        echo -e "${GREEN}Configuration saved successfully!${NC}"
    else
        if sudo mv "$TEMP_CONFIG_FILE" "$CONFIG_FILE" 2>/dev/null; then
            echo -e "${GREEN}Configuration saved successfully! (with sudo)${NC}"
        else
            echo -e "${RED}Failed to save configuration. Please run with sudo or check permissions.${NC}"
            rm -f "$TEMP_CONFIG_FILE"
            return 1
        fi
    fi
}

# Function to display current status
show_status() {
    local current_ssid=$(get_current_ssid)
    local mapping_count=$(load_mappings | wc -l | xargs)
    local os_version=$(sw_vers -productVersion | cut -d. -f1)
    
    echo -e "${YELLOW}Current Status:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    printf "│ Current Wi-Fi: %-45s │\n" "$current_ssid"
    printf "│ Mappings:      %-45s │\n" "$mapping_count"
    echo -e "└─────────────────────────────────────────────────────────────┘"
    
    # Show privacy notice for macOS 26.0+
    if [ "$os_version" -ge "26" ] && [[ "$current_ssid" == *"Privacy Protected"* || "$current_ssid" == "<redacted>" ]]; then
        echo -e "${YELLOW}Note:${NC} macOS 26.0+ has enhanced privacy protections."
        echo -e "      To get SSID detection working:"
        echo -e "      1. Create a Shortcuts app shortcut named 'Current Wi-Fi'"
        echo -e "      2. Or manually enter your SSID mappings below"
        echo
    fi
    echo
}

# Function to display mappings
show_mappings() {
    echo -e "${YELLOW}SSID Mappings:${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────┐"
    
    local mappings_output=$(load_mappings)
    if [[ -z "$mappings_output" ]]; then
        echo -e "│ No mappings configured                                     │"
    else
        while IFS= read -r mapping; do
            if [[ -n "$mapping" ]]; then
                local location=$(echo "$mapping" | awk '{print $1}')
                local ssid=$(echo "$mapping" | cut -d' ' -f2- | sed 's/^"//;s/"$//')
                printf "│ %-15s %-45s │\n" "$location" "$ssid"
            fi
        done <<< "$mappings_output"
    fi
    
    echo -e "└─────────────────────────────────────────────────────────────┘"
    echo
}

# Function to add mapping
add_mapping() {
    local current_ssid=$(get_current_ssid)
    local locations=($(get_available_locations))
    
    echo -e "${YELLOW}Add SSID Mapping:${NC}"
    echo "Available locations: ${locations[*]}"
    echo "Current SSID: $current_ssid"
    echo
    
    read -p "Enter location name: " location
    if [[ -z "$location" ]]; then
        echo -e "${RED}Invalid location name${NC}"
        return 1
    fi
    
    read -p "Enter SSID (or press Enter to use current '$current_ssid'): " ssid
    if [[ -z "$ssid" ]]; then
        ssid="$current_ssid"
    fi
    
    if [[ -z "$ssid" ]]; then
        echo -e "${RED}Invalid SSID${NC}"
        return 1
    fi
    
    # Quote SSID if it contains spaces
    if [[ "$ssid" == *" "* ]]; then
        ssid="\"$ssid\""
    fi
    
    local new_mapping="$location $ssid"
    local mappings_output=$(load_mappings)
    local mappings=()
    
    if [[ -n "$mappings_output" ]]; then
        while IFS= read -r mapping; do
            if [[ -n "$mapping" ]]; then
                mappings+=("$mapping")
            fi
        done <<< "$mappings_output"
    fi
    
    mappings+=("$new_mapping")
    
    if save_mappings "${mappings[@]}"; then
        echo -e "${GREEN}Mapping added: $location -> $ssid${NC}"
    else
        echo -e "${RED}Failed to add mapping${NC}"
        return 1
    fi
}

# Function to remove mapping
remove_mapping() {
    local mappings_output=$(load_mappings)
    local mappings=()
    
    if [[ -n "$mappings_output" ]]; then
        while IFS= read -r mapping; do
            if [[ -n "$mapping" ]]; then
                mappings+=("$mapping")
            fi
        done <<< "$mappings_output"
    fi
    
    if [[ ${#mappings[@]} -eq 0 ]]; then
        echo -e "${RED}No mappings to remove${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Remove SSID Mapping:${NC}"
    for i in "${!mappings[@]}"; do
        local mapping="${mappings[$i]}"
        local location=$(echo "$mapping" | awk '{print $1}')
        local ssid=$(echo "$mapping" | cut -d' ' -f2- | sed 's/^"//;s/"$//')
        echo "$((i+1)). $location -> $ssid"
    done
    
    read -p "Enter mapping number to remove: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#mappings[@]} ]]; then
        echo -e "${RED}Invalid selection${NC}"
        return 1
    fi
    
    local index=$((choice-1))
    local removed="${mappings[$index]}"
    unset mappings[$index]
    
    if save_mappings "${mappings[@]}"; then
        echo -e "${GREEN}Removed mapping: $removed${NC}"
    else
        echo -e "${RED}Failed to remove mapping${NC}"
        return 1
    fi
}

# Function to install LocationChanger
install_locationchanger() {
    echo -e "${YELLOW}Install LocationChanger${NC}"
    echo "This will install LocationChanger using the install.sh script."
    echo
    
    # Check if install.sh exists
    if [[ ! -f "./install.sh" ]]; then
        echo -e "${RED}Error: install.sh not found in current directory${NC}"
        echo "Please run this script from the LocationChanger project directory."
        return 1
    fi
    
    # Check if we have any mappings to preserve
    local mappings_output=$(load_mappings)
    local has_mappings=false
    if [[ -n "$mappings_output" ]]; then
        has_mappings=true
        echo "Found existing mappings that will be preserved:"
        while IFS= read -r mapping; do
            if [[ -n "$mapping" ]]; then
                local location=$(echo "$mapping" | awk '{print $1}')
                local ssid=$(echo "$mapping" | cut -d' ' -f2- | sed 's/^"//;s/"$//')
                echo "  - $location -> $ssid"
            fi
        done <<< "$mappings_output"
        echo
    fi
    
    read -p "Do you want to proceed with installation? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing LocationChanger...${NC}"
        
        # Run the install script
        if ./install.sh; then
            echo -e "${GREEN}LocationChanger installed successfully!${NC}"
            
            # Restore mappings if they exist
            if [[ "$has_mappings" == true ]]; then
                echo "Restoring existing mappings..."
                local mappings=()
                while IFS= read -r mapping; do
                    if [[ -n "$mapping" ]]; then
                        mappings+=("$mapping")
                    fi
                done <<< "$mappings_output"
                
                if save_mappings "${mappings[@]}"; then
                    echo -e "${GREEN}Existing mappings restored successfully!${NC}"
                else
                    echo -e "${YELLOW}Warning: Failed to restore mappings. You may need to reconfigure them.${NC}"
                fi
            fi
            
            echo
            echo -e "${GREEN}Installation complete!${NC}"
            echo -e "${YELLOW}Next steps:${NC}"
            echo "1. Add the following line to your sudoers file:"
            echo "   Run: sudo visudo"
            echo "   Add: your_username ALL=(ALL) NOPASSWD: /usr/local/bin/locationchanger-helper"
            echo "   (Replace 'your_username' with your actual username)"
            echo
            echo "2. Configure your SSID mappings using this tool (option 1)"
            echo "3. Test the service by changing Wi-Fi networks"
            echo
        else
            echo -e "${RED}Installation failed!${NC}"
            echo "Please check the error messages above and try again."
            return 1
        fi
    else
        echo -e "${YELLOW}Installation cancelled.${NC}"
    fi
}

# Function to uninstall LocationChanger
uninstall_locationchanger() {
    echo -e "${YELLOW}Uninstall LocationChanger${NC}"
    echo "This will remove all LocationChanger files and configurations."
    echo
    echo "Files that will be removed:"
    echo "  - /usr/local/bin/locationchanger"
    echo "  - /usr/local/bin/locationchanger-helper"
    echo "  - /usr/local/bin/locationchanger.conf"
    echo "  - /usr/local/bin/locationchanger.conf.backup"
    echo "  - ~/Library/LaunchAgents/LocationChanger.plist"
    echo "  - /usr/local/var/log/locationchanger.log"
    echo "  - /usr/local/bin/locationchanger.callout.sh (if exists)"
    echo
    read -p "Are you sure you want to uninstall? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Uninstalling LocationChanger...${NC}"
        
        # Stop and remove launch agent
        if launchctl list | grep -q "locationchanger" 2>/dev/null; then
            echo "Stopping LocationChanger service..."
            if [[ -f ~/Library/LaunchAgents/LocationChanger.plist ]]; then
                launchctl unload ~/Library/LaunchAgents/LocationChanger.plist 2>/dev/null || true
            fi
        fi
        
        # Remove files with sudo if needed
        local files_to_remove=(
            "/usr/local/bin/locationchanger"
            "/usr/local/bin/locationchanger-helper"
            "/usr/local/bin/locationchanger.conf"
            "/usr/local/bin/locationchanger.conf.backup"
            "/usr/local/bin/locationchanger.callout.sh"
        )
        
        for file in "${files_to_remove[@]}"; do
            if [[ -f "$file" ]]; then
                if sudo rm -f "$file" 2>/dev/null; then
                    echo -e "${GREEN}Removed: $file${NC}"
                else
                    echo -e "${RED}Failed to remove: $file${NC}"
                fi
            fi
        done
        
        # Remove launch agent plist
        if [[ -f ~/Library/LaunchAgents/LocationChanger.plist ]]; then
            if rm -f ~/Library/LaunchAgents/LocationChanger.plist; then
                echo -e "${GREEN}Removed: ~/Library/LaunchAgents/LocationChanger.plist${NC}"
            else
                echo -e "${RED}Failed to remove: ~/Library/LaunchAgents/LocationChanger.plist${NC}"
            fi
        fi
        
        # Remove log file
        if [[ -f /usr/local/var/log/locationchanger.log ]]; then
            if sudo rm -f /usr/local/var/log/locationchanger.log 2>/dev/null; then
                echo -e "${GREEN}Removed: /usr/local/var/log/locationchanger.log${NC}"
            else
                echo -e "${RED}Failed to remove: /usr/local/var/log/locationchanger.log${NC}"
            fi
        fi
        
        # Remove log directory if empty
        if [[ -d /usr/local/var/log ]] && [[ -z "$(ls -A /usr/local/var/log 2>/dev/null)" ]]; then
            sudo rmdir /usr/local/var/log 2>/dev/null || true
        fi
        
        echo
        echo -e "${GREEN}LocationChanger has been uninstalled successfully!${NC}"
        echo -e "${YELLOW}Note: You may want to remove the sudoers entry manually:${NC}"
        echo "Run: sudo visudo"
        echo "Remove the line: your_username ALL=(ALL) NOPASSWD: /usr/local/bin/locationchanger-helper"
        echo
    else
        echo -e "${YELLOW}Uninstall cancelled.${NC}"
    fi
}

# Function to show menu
show_menu() {
    echo -e "${YELLOW}Commands:${NC}"
    echo "  1. Add SSID mapping"
    echo "  2. Remove SSID mapping"
    echo "  3. Refresh current SSID"
    echo "  4. View configuration file"
    echo "  5. Install LocationChanger"
    echo "  6. Uninstall LocationChanger"
    echo "  7. Exit"
    echo
    read -p "Enter choice (1-7): " choice
}

# Main loop
main() {
    while true; do
        print_header
        show_status
        show_mappings
        show_menu
        
        case "$choice" in
            1)
                add_mapping
                ;;
            2)
                remove_mapping
                ;;
            3)
                current_ssid=$(get_current_ssid)
                echo -e "${GREEN}Current SSID: $current_ssid${NC}"
                ;;
            4)
                if [[ -f "$CONFIG_FILE" ]]; then
                    echo -e "${YELLOW}Configuration file contents:${NC}"
                    echo "──────────────────────────────────────────────────────────────"
                    cat "$CONFIG_FILE"
                    echo "──────────────────────────────────────────────────────────────"
                else
                    echo -e "${RED}Configuration file not found at $CONFIG_FILE${NC}"
                fi
                ;;
            5)
                install_locationchanger
                ;;
            6)
                uninstall_locationchanger
                ;;
            7)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1-7.${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Check if running as root for config file access
if [[ ! -w "/usr/local/bin" ]] && [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${YELLOW}Note: Cannot write to /usr/local/bin without sudo. The script will prompt for sudo when needed.${NC}"
    echo "The configuration file will be created at: $CONFIG_FILE"
    echo
fi

main
