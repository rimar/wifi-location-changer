# Mac OSX Wi-Fi Location Changer

* Automatically changes the Mac OSX network location when Wi-Fi connection SSID changes
* Allows having different IP settings depending on the Wi-Fi SSID

**Note:** Mountain Lion compatible

## Configuration
There are two areas that need to be modified in the locationchanger script, Locations and SSIDs. Both of which are case sensitive. 

### Locations
Edit locationchanger and change/add locations to be set:

**Note:** Ensure you use the exact names as they appear under "Location" in OSX's System Preferences -> Network

```bash
# LOCATIONS 
Location_Automatic="Automatic"
Location_Work="Company Intranet"
```

### SSIDs
Edit locationchanger and add/edit SSIDs to be detected:

```bash
# SSIDS
SSID_TelekomPublic=Telekom
SSID_Home=HomeSSID
SSID_Work=WorkSSID
```

Edit/Add SSID -> LOCATION mapping to list:

```bash
# SSID -> LOCATION mapping
case $SSID in
	$SSID_TelekomPublic ) LOCATION="$Location_Automatic";;
	$SSID_Home          ) LOCATION="$Location_Automatic";;
	$SSID_Work  ) LOCATION="$Location_Work";;
	# ... add more here
```

### MacOS Notifications
The script triggers a MacOS Notification, if you don't want this just delete the three lines that start with `osascript` around line 57. If you add or delete Locations, the case needs to be updated.

```bash
case $LOCATION in
        $Location_Automatic )
                # do stuff here you would do in Location_Automatic
                osascript -e 'display notification "Network Location Changed to Automatic" with title "Network Location Changed"'
        ;;

        $Location_Home )
                osascript -e 'display notification "Network Location Changed to Home" with title "Network Location Changed"'
        ;;

        $Location_Work )
                osascript -e 'display notification "Network Location Changed to Work" with title "Network Location Changed"'
        ;;
				# ... add more here
esac
```

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
cp LocationChanger.plist ~/Library/LaunchAgents/
```
Should you place the locationchanger script to another location, make sure you edit the path in LocationChanger.plist too.

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
