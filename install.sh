#!/usr/bin/env bash

sudo mkdir -p /usr/local/bin
sudo cp locationchanger /usr/local/bin
cp LocationChanger.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/LocationChanger.plist
