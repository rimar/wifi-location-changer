#WiFi Location Changer
* Automatically change location when wifi connection changes in Mac OS X
* Allows having different IP settings depending on the wifi SSID
* Automatically select the location corresponding to the SSID, if none
  exists: select the "auto" location

Simplified location changer based on http://tech.inhelsinki.nl/locationchanger/

##Installation
Notes: the location name should be the same as the name of SSID and the plist must be owned by root to avoid the `Dubious ownership on file` security issue (see this [SO post][so]).

    cp locationchanger /usr/local/bin
    cp LocationChanger.plist ~/Library/LaunchAgents/
    sudo chown root ~/Library/LaunchAgents/LocationChanger.plist
    sudo launchctl load ~/Library/LaunchAgents/LocationChanger.plist

[so]: https://apple.stackexchange.com/questions/3250/why-am-i-getting-a-dubious-ownership-of-file-error-when-launch-agent-runs-my
