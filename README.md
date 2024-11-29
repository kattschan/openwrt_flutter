# openwrt_flutter

An app to view stats about your OpenWRT instance on the go. Currently shows WiFi details and devices.

# Setup instructions

openwrt_flutter uses ubus to retrieve information. By default, you cannot retrieve information from ubus over the network, so you will need to configure it based on the instructions found [here](https://openwrt.org/docs/techref/ubus). I just setup the superuser config since my router isn't exposed to the internet, but you can allow it fine grained access as you prefer.

# Demo
