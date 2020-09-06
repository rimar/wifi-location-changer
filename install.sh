#!/bin/bash

chmod +x locationchanger
sudo mkdir -p /usr/local/bin
sudo cp -a locationchanger /usr/local/bin
cp LocationChanger.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/LocationChanger.plist
launchctl load ~/Library/LaunchAgents/LocationChanger.plist