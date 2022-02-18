#!/bin/bash

set -eu

chmod +x locationchanger
sudo mkdir -p /usr/local/bin
sudo cp -a locationchanger /usr/local/bin
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
