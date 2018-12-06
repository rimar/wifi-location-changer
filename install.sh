#!/bin/bash

sudo cp locationchanger /usr/local/bin
cp LocationChanger.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/LocationChanger.plist