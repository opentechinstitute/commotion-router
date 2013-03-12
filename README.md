##Commotion-OpenWRT

Commotion is an open source “device-as-infrastructure” communication platform that integrates users’ existing cell phones, Wi-Fi enabled computers, and other wireless-capable devices to create community- and metro-scale, peer-to-peer communications networks.

This repoencompasses the development of the OpenWRT router firmware component of the Commotion Wireless project. This repo, installs the following other Commotion projects in order to become a fully configured Commotion Node.

###The Commotion Daemon

https://github.com/opentechinstitute/commotiond.git

The commotion daemon is an embedded daemon and library that provides a common interface for manging wireless mesh networks. 

###Commotion Quick-Start

https://github.com/opentechinstitute/commotion-quick-start

The quickstart is a easy to understand interface that allows a new user to quickly configure a node to their needs. 

###Commotion Theme

https://github.com/opentechinstitute/commotion-openwrt-theme

The Commotion Open-WRT theme for the web-interface on Commotion wireless routers.

###Commotion-Apps

https://github.com/opentechinstitute/commotion-apps

The application suite allows for developers to easily advertise applications over a commotion mesh using mdns, users to easily find applications through the router app advertising interface, and node owners to easily manage and customize their application portals to better support community application support. 

###Serval Crypto

https://github.com/opentechinstitute/serval-crypto

Servals key management daemon allows transparent encryption and authentication of messages. 

###Commotion Debug Helper

https://github.com/opentechinstitute/commotion-bug-info

The debuggin helper creates custom, downloadable informational debugging documents for offline debugging, or to send to network maintainers. Each of these new tools needs testing to find errors as well as to ensure their usability.


##Installation
                                                         

How to create a Commotion image from source: (the really really quick guide)

Run the following commands: (the $ signify the command line. Do not type the $)

`$ git clone https://github.com/opentechinstitute/commotion-openwrt.git`

`$ cd commotion-openwrt/`

`$ git checkout DR1-testing`

`$ ./setup`

`$ cd openwrt/`

`$ make menuconfig`

"This will open a menu to allow you to choose your wireless chipset and customize your install"

`$ make V=99`

`$ cd bin/`

"you will find a folder with the name of your wireless chip here. Within this folder lies images you can install on your wireless router"

####Installation Instructions: (Ubiquity Devices)

https://code.commotionwireless.net/projects/commotion-manual/wiki/Installing_Commotion_on_Wireless_Nodes

####Detailed Installation Instructions: (Ubiquity Devices)

https://code.commotionwireless.net/projects/commotion-manual/wiki/Detailed_TFTP_Instructions

####How to Update an existing Commotion node:

https://code.commotionwireless.net/projects/commotion-manual/wiki/Updating_the_Commotion_software_on_your_router
