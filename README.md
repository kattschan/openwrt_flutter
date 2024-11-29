# openwrt_flutter

An app to view stats about your OpenWRT instance on the go. Currently shows WiFi details and devices. **If you're watching the demo I recommend 2x speed**

# Setup instructions

openwrt_flutter uses ubus to retrieve information. By default, you cannot retrieve information from ubus over the network, so you will need to configure it based on the instructions found [here](https://openwrt.org/docs/techref/ubus). I just setup the superuser config since my router isn't exposed to the internet, but you can allow it fine grained access as you prefer.

# Demo
<img src="https://github.com/user-attachments/assets/d4c3f670-ce2a-4dd9-8eb5-244bcb9d13fa" width="256">
<img src="https://github.com/user-attachments/assets/0884d888-8284-4de1-8398-edf0516ae1dc" width="256">
<img src="https://github.com/user-attachments/assets/fd2db47e-b0d6-4620-9405-9a5d8692c03f" width="256">

https://github.com/user-attachments/assets/9a29323c-d8df-469e-8e67-86aa09f5812b
