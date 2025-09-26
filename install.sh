#!/bin/bash

set -eu

chmod +x locationchanger
chmod +x locationchanger-helper
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/var/log
sudo cp -a locationchanger /usr/local/bin
sudo cp -a locationchanger-helper /usr/local/bin
sudo chown root /usr/local/bin/locationchanger-helper
sudo chmod 500 /usr/local/bin/locationchanger-helper
sudo chown root:wheel /usr/local/var/log
sudo chmod 755 /usr/local/var/log
cp LocationChanger.plist ~/Library/LaunchAgents/

# remove older service if found
launchctl list | grep --quiet "locationchanger" && launchctl unload ~/Library/LaunchAgents/LocationChanger.plist

# conditionalize on macos version
major_version=$(sw_vers -productVersion | awk -F. '{ print $1; }')

if [[ $major_version -ge 11 ]]; then
    # "big sur" or later

    # service name includes user ID
    loggedInUser=$( ls -l /dev/console | awk '{print $3}' )
    userID=$( id -u $loggedInUser )
    service_name="gui/$userID/locationchanger"

    # fyi, removal of new service can be done via:
    # sudo launchctl bootout $service_name

    # bootstrap (install) as necessary
    sudo launchctl print $service_name >> /dev/null 2>&1 || sudo launchctl bootstrap gui/$userID ~/Library/LaunchAgents/LocationChanger.plist

    sudo launchctl enable $service_name

    # kickstart -k will RESTART process, using any updated code
    sudo launchctl kickstart -k $service_name
    echo "The service \"$service_name\" has been installed and started"
else
    # for older macos

    launchctl load ~/Library/LaunchAgents/LocationChanger.plist
    echo "The service \"locationchanger\" has been installed and started"
fi

# install any external callout that is present
EXTERNAL_CALLOUT_FILE="./locationchanger.callout.sh"
if [[ -f "$EXTERNAL_CALLOUT_FILE" ]]; then
    chmod +x $EXTERNAL_CALLOUT_FILE
    sudo cp -a $EXTERNAL_CALLOUT_FILE /usr/local/bin
    echo "An external callout ($EXTERNAL_CALLOUT_FILE) was installed also"
fi

# install mapping file
MAPPING_FILE="./locationchanger.conf"
if [[ -f "$MAPPING_FILE" ]]; then
    sudo cp -a $MAPPING_FILE /usr/local/bin
fi

echo ""
echo "IMPORTANT: For location switching to work, you need to add the following line to your sudoers file:"
echo "Run: sudo visudo"
echo "Add this line (replace 'your_username' with your actual username):"
echo "your_username ALL=(ALL) NOPASSWD: /usr/local/bin/locationchanger-helper"
echo ""
echo "To find your username, run: whoami"
echo ""
