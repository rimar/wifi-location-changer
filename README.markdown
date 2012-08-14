#Wi-Fi Location Changer

* Automatically changes the network location when Wi-Fi connection SSID changes in Mac OSX
* Allows having different IP settings depending on the Wi-Fi SSID

Based on http://tech.inhelsinki.nl/locationchanger/
Forked from https://github.com/rimar/wifi-location-changer/

Mountain Lion compatible, Lion too (pretty sure also Snow Leopard and before)

##Installation
Edit locationchanger and change the configuration array like this

    locations['My_SSID_home'] = 'At Home'
    locations['My_SSID_work'] = 'At Work'
	locations['My_SSID_bar']  = 'At the Bar'

Copy these files (change paths as needed)

    cp locationchanger /usr/local/bin
    cp LocationChanger.plist ~/Library/LaunchAgents/
    launchctl load ~/Library/LaunchAgents/LocationChanger.plist

##Customization
Logfile location

    tail -f /usr/local/var/log/locationchanger.log

##ToDos

- Arrays for Config: locations['SSID'] = 'something': http://tldp.org/LDP/abs/html/arrays.html