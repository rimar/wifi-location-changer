#!/bin/bash

# Copy LocationChanger files:
sudo cp locationchanger /usr/local/bin
cp LocationChanger.plist ~/Library/LaunchAgents/
# Make locationchanger script executable:
sudo chmod +x /usr/local/bin/locationchanger
# Load LocationChanger.plist as a launchd daemon:
launchctl unload -w ~/Library/LaunchAgents/LocationChanger.plist
launchctl load -w ~/Library/LaunchAgents/LocationChanger.plist
