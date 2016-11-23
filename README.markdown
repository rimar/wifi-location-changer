#WiFi Location Changer for SAP Macbooks
* Automatically change location when wifi connection changes in Mac OS X
* Allows having different IP settings depending on the wifi SSID
* Allows you to define a list of SSID -> Location associations, including a fallback, OR
* Automatically select the location corresponding to the SSID, if none
  exists: select the "auto" location

Note: location name should be the same as the name of SSID with all spaces removed. 
For example: **SSID**: ```My WiFi Hotspot``` Will translate to **Location Name**: ```MyWiFiHotspot``` 

Based on https://github.com/rimar/wifi-location-changer

##Installation

1. Run the installation script

    ./install

2. Customize the SSID and location names in ```~/.locationchanger``` as needed

