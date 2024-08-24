# Mac OSX Wi-Fi Location Changer

* Automatically changes the Mac OSX network location & custom DNS settings when a configured Wi-Fi (SSID) becomes connected
* Allows having different IP settings depending on the Wi-Fi SSID
* Offers hook to run external script when location changes
* macOS Sonoma 14.4.1 tested

## Configuration
Create a configuration file using the sample:

```bash
cp ./locationchanger.conf.sample ./locationchanger.conf
```

Add to this new file (`./locationchanger.conf`) a single line for each pair of location and SSID that you want this service to recognize and set when the SSID connects. That is, for each location, add one line with both a location name and a Wi-Fi SSID, separated by a space, taking care to use exact capitalization, and using quotations as necessary.

For example, if your location is "home", and the Wi-Fi SSID to trigger that location is "myWifiName", then a line in the configuration file would look like:

`home myWifiName`

If your SSID is instead a name like Wu Tang LAN, with spaces, then use quotes around the SSID like:

`home "Wu Tang LAN"`

**Note:** Ensure you use the exact location names as they appear under "Location" in OSX's System Preferences -> Network, and for SSIDs in your Wi-Fi menu. Capitalization must match! Spaces must match within a quoted name!

Add as many location + SSID lines as you like to the configuration file.

### MacOS Notifications
The script triggers a MacOS Notification upon changing location. If you don't want this just delete the lines that start with `osascript`.

## Installation

### Automated Installation

Execute:
```bash
./install.sh
```

### Manual Installation

Copy these files:
```bash
cp locationchanger /usr/local/bin
cp locationchanger.conf /usr/local/bin
cp LocationChanger.plist ~/Library/LaunchAgents/
```
Should you place the locationchanger script to another location, make sure you edit the path in LocationChanger.plist too.

Make locationchanger script executable:
```bash
chmod +x /usr/local/bin/locationchanger
```
Load LocationChanger.plist as a launchd daemon:
```bash
launchctl load ~/Library/LaunchAgents/LocationChanger.plist
```
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

```
tail /usr/local/var/log/locationchanger.log
```

## MacOS Ventura fallback to Automatic location issue

This repository already handles the case already if the SSID is not listed in the config file. In that case it should switch to the location `Automatic`, but it requires root access to do so.
If you want that it changes the settings without the need to execute it again for each new network with root credentials just add to following to settings and install it again with `./install.sh`:

### Add `<string>/usr/bin/sudo</string>` within the array config
```xml
# LocationChanger.plist
...
<array>
    <string>/usr/bin/sudo</string>
    <string>/usr/local/bin/locationchanger</string>
</array>
...
```

### Modify the sudoers file
- Run `sudo visudo`
- replace `your_user_name` with your username
  - you can type `whoami` to see you current username

```
# User privilege specification
root    ALL=(ALL) ALL
%admin  ALL=(ALL) ALL
your_user_name ALL=(ALL) NOPASSWD: /usr/local/bin/locationchanger
```

Run the `./install.sh` script again - and now your location network settings are set to `Automatic` if no mapping has been found!  
