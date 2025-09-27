# Mac OSX Wi-Fi Location Changer

* Automatically changes the Mac OSX network location when a configured Wi-Fi (SSID) becomes connected
* Allows having different IP settings depending on the Wi-Fi SSID
* Offers hook to run external script when location changes

## Quick Start

### Easy Installation and Configuration

1. **Install LocationChanger**:
   ```bash
   ./install.sh
   ```

2. **Configure SSID mappings**:
   ```bash
   ./config-ui.sh
   ```
   - Select option 1 to add SSID mappings
   - Select option 5 to install if not already done

3. **Set up sudoers** (required for location switching):
   ```bash
   sudo visudo
   ```
   Add this line (replace `your_username` with your actual username):
   ```
   your_username ALL=(ALL) NOPASSWD: /usr/local/bin/locationchanger-helper
   ```

4. **Test the service** by switching between different Wi-Fi networks

### Configuration

The easiest way to configure LocationChanger is using the interactive configuration tool:

```bash
./config-ui.sh
```

This provides a user-friendly interface for all configuration tasks. See the [Configuration UI](#configuration-ui) section below for detailed instructions.

### MacOS Notifications
The script triggers a MacOS Notification upon changing location. If you don't want this just delete the lines that start with `osascript`.

## Installation

### Recommended: Using the Configuration Tool

The easiest way to install LocationChanger is through the configuration tool:

```bash
./config-ui.sh
```

Then select option 5 (Install LocationChanger). This will:
- Run the installation script
- Preserve any existing configurations
- Provide guidance for next steps

### Automated Installation

Execute:
```bash
./install.sh
```

### Manual Installation

Copy these files:
```bash
cp locationchanger /usr/local/bin
cp locationchanger-helper /usr/local/bin
cp locationchanger.conf /usr/local/bin
cp LocationChanger.plist ~/Library/LaunchAgents/
```

Make scripts executable:
```bash
chmod +x /usr/local/bin/locationchanger
chmod +x /usr/local/bin/locationchanger-helper
sudo chown root /usr/local/bin/locationchanger-helper
sudo chmod 500 /usr/local/bin/locationchanger-helper
```

Load LocationChanger.plist as a launchd daemon:
```bash
launchctl load ~/Library/LaunchAgents/LocationChanger.plist
```

**Note:** Should you place the locationchanger script to another location, make sure you edit the path in LocationChanger.plist too.

## Logfile

Logfile location can be adjusted in locationchanger, around line 12:
```bash
exec &>/usr/local/var/log/locationchanger.log
```
See log in action:
```bash
tail -f /usr/local/var/log/locationchanger.log
```

## Run arbitrary script when location changes

By convention, placing an executable script in this directory with name:

`locationchanger.callout.sh`

and then running the installer, will cause the locationchanger service to run that script each time location changes.

### Testing

For ease in testing, configure two locations within the current environment, e.g., "home" and "guest", each associated with a different SSID, such as the main SSID and guest SSID on your router. Then using the Wi-Fi menu, toggle between those SSIDs. You can see any success or error messages that are written to the log with a command like:

```bash
tail /usr/local/var/log/locationchanger.log
```

### Uninstallation

#### Using the Configuration Tool (Recommended)

```bash
./config-ui.sh
```

Select option 6 (Uninstall LocationChanger) for a complete removal of all files and configurations.

#### Manual Uninstallation

```bash
# Stop the service
launchctl unload ~/Library/LaunchAgents/LocationChanger.plist

# Remove files
sudo rm -f /usr/local/bin/locationchanger
sudo rm -f /usr/local/bin/locationchanger-helper
sudo rm -f /usr/local/bin/locationchanger.conf
sudo rm -f /usr/local/bin/locationchanger.conf.backup
sudo rm -f /usr/local/bin/locationchanger.callout.sh
rm -f ~/Library/LaunchAgents/LocationChanger.plist
sudo rm -f /usr/local/var/log/locationchanger.log

# Remove sudoers entry manually
sudo visudo
# Remove the line: your_username ALL=(ALL) NOPASSWD: /usr/local/bin/locationchanger-helper
```

## macOS Compatibility and Security

### macOS Tahoe 26.0+ Support
This version includes support for macOS Tahoe 26.0+ by using the Shortcuts app to detect Wi-Fi SSIDs when traditional methods fail. The script automatically falls back to legacy methods if Shortcuts is not available.

**Note:** macOS 26.0+ has enhanced privacy protections that may prevent automatic SSID detection. If you see `Privacy Protected` or `<redacted>` in the configuration tool, you can still manually configure SSID mappings. For automatic detection, create a Shortcuts app shortcut named "Current Wi-Fi".

### How To Create "Current WiFi" Shortcut:

Open the *Shortcuts* app → click **+** to add a new shortcut → in the right pane select *Device* → drag **Get Network Details** to the left pane → then go to the *Scripting* section, find **Stop and Output**, and drag it below → run it with the *Play* button (you should see your current Wi-Fi name) → name the shortcut **Current WiFi** (at the top of the window) → close the window and the app.

Should look like this:
<img width="2446" height="1624" alt="Shortcuts App New shortcut 3" src="https://github.com/user-attachments/assets/9eae481c-4881-478b-a9a2-86c0363a955e" />


### Secure Location Switching
Starting with macOS Sequoia 15.5+, changing network locations requires admin privileges. This project uses a secure helper script approach to minimize security risks.

**Security Benefits:**
- Only the specific helper script can be executed without password
- Helper script is owned by root with restricted permissions (500)
- Helper script only allows network location switching, preventing privilege escalation
- Input validation prevents injection attacks

### Automatic Location Fallback
If no SSID mapping is found in the configuration file, the script automatically switches to the "Automatic" location. This requires the same sudoers configuration as above.

## Configuration UI

A comprehensive command-line configuration tool is available for easy management of LocationChanger.

<img width="1070" height="1036" alt="Bash Configuration UI" src="https://github.com/user-attachments/assets/4e88c5bf-932a-4c91-8584-a9842a7a2a24" />

### Using the Configuration Tool

```bash
./config-ui.sh
```

This interactive tool provides a complete management interface with the following features:

#### Menu Options

1. **Add SSID mapping** - Create new Wi-Fi to location mappings
2. **Remove SSID mapping** - Delete existing mappings
3. **Refresh current SSID** - Update current Wi-Fi status
4. **View configuration file** - Display current configuration
5. **Install LocationChanger** - Run the installation script and preserve existing mappings
6. **Uninstall LocationChanger** - Complete removal of all files and configurations
7. **Exit** - Quit the configuration tool

#### Features

- **Visual Interface**: Clean, colorized terminal interface with clear status displays
- **Current Status**: Shows current Wi-Fi SSID and mapping count
- **Smart Installation**: Preserves existing mappings during installation
- **Complete Uninstall**: Removes all files, configurations, and services
- **Error Handling**: Comprehensive error checking and user feedback
- **Permission Management**: Handles sudo requirements automatically

#### Example Usage

```bash
# Start the configuration tool
./config-ui.sh

# The tool will show:
# - Current Wi-Fi status
# - Existing mappings
# - Interactive menu for all operations
```

#### Installation via UI

1. Run `./config-ui.sh`
2. Select option 5 (Install LocationChanger)
3. The tool will:
   - Check for existing mappings
   - Run the installation script
   - Restore your configurations
   - Provide next steps for sudoers setup

#### Uninstallation via UI

1. Run `./config-ui.sh`
2. Select option 6 (Uninstall LocationChanger)
3. Confirm the removal
4. The tool will:
   - Stop the service
   - Remove all files
   - Clean up configurations
   - Provide guidance for sudoers cleanup

### Manual Configuration (Alternative)

If you prefer manual configuration, create a configuration file using the sample:

```bash
cp ./locationchanger.conf.sample ./locationchanger.conf
```

Add to this new file (`./locationchanger.conf`) a single line for each pair of location and SSID that you want this service to recognize and set when the SSID connects. That is, for each location, add one line with both a location name and a Wi-Fi SSID, separated by a space, taking care to use exact capitalization, and using quotations as necessary.

For example, if your location is "home", and the Wi-Fi SSID to trigger that location is "myWifiName", then a line in the configuration file would look like:

`home myWifiName`

If your SSID is instead a name like Wu Tang LAN, with spaces, then use quotes around the SSID like:

`home "Wu Tang LAN"`

**Note:** Ensure you use the exact location names as they appear under "Location" in OSX's System Preferences -> Network, and for SSIDs in your Wi-Fi menu. Capitalization must match! Spaces must match within a quoted name!

## Required Setup

**Manual Setup (Required for location switching):**

1. Run `./install.sh` to install the helper script
2. Add the following line to your sudoers file:
   ```bash
   sudo visudo
   ```
   Add this line (replace `your_username` with your actual username):
   ```
   your_username ALL=(ALL) NOPASSWD: /usr/local/bin/locationchanger-helper
   ```
   To find your username: `whoami`  
