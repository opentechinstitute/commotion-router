                                      _   _                                                       _   
   ___ ___  _ __ ___  _ __ ___   ___ | |_(_) ___  _ __         ___  _ __   ___ _ ____      ___ __| |_ 
  / __/ _ \| '_ ` _ \| '_ ` _ \ / _ \| __| |/ _ \| '_ \ _____ / _ \| '_ \ / _ \ '_ \ \ /\ / / '__| __|
 | (_| (_) | | | | | | | | | | | (_) | |_| | (_) | | | |_____| (_) | |_) |  __/ | | \ V  V /| |  | |_ 
  \___\___/|_| |_| |_|_| |_| |_|\___/ \__|_|\___/|_| |_|      \___/| .__/ \___|_| |_|\_/\_/ |_|   \__|
                                                                   |_|                                

=======================================================================================================

The Commotion Daemon

The commotion daemon is an embedded daemon and library that provides a common interface for manging wireless mesh networks. 

Commotion Quick-Start
https://github.com/opentechinstitute/commotion-quick-start
The quickstart is a easy to understand interface that allows a new user to quickly configure a node to their needs. 

Commotion Theme
https://github.com/opentechinstitute/commotion-openwrt-theme
The Commotion Open-WRT theme for the web-interface on Commotion wireless routers.

Commotion-Apps
https://github.com/opentechinstitute/commotion-apps
The application suite allows for developers to easily advertise applications over a commotion mesh using mdns, users to easily find applications through the router app advertising interface, and node owners to easily manage and customize their application portals to better support community application support. 

Serval Crypto
https://github.com/opentechinstitute/serval-crypto
Servals key management daemon allows transparent encryption and authentication of messages. 

Commotion Debug Helper
https://github.com/opentechinstitute/commotion-bug-info
The debuggin helper creates custom, downloadable informational debugging documents for offline debugging, or to send to network maintainers. Each of these new tools needs testing to find errors as well as to ensure their usability.


=========================================================================================================
 _                        _ _              _             
| |             _        | | |         _  (_)            
| |____   ___ _| |_ _____| | | _____ _| |_ _  ___  ____  
| |  _ \ /___|_   _|____ | | |(____ (_   _) |/ _ \|  _ \ 
| | | | |___ | | |_/ ___ | | |/ ___ | | |_| | |_| | | | |
|_|_| |_(___/   \__)_____|\_)_)_____|  \__)_|\___/|_| |_|
                                                         

How to create a Commotion image from source: (the really really quick guide)
Run the following commands

git clone https://github.com/opentechinstitute/commotion-openwrt.git
cd commotion-openwrt/
git checkout DR1-testing
./setup
cd openwrt/
make menuconfig
#This will open a menu to allow you to choose your wireless chipset and customize your install
make V=99
cd bin/
#you will find a folder with the name of your wireless chip here. Within this folder lies images you can install on your wireless router

Installation Instructions: (Ubiquity Devices)
https://code.commotionwireless.net/projects/commotion-manual/wiki/Installing_Commotion_on_Wireless_Nodes

Detailed Installation Instructions: (Ubiquity Devices)
https://code.commotionwireless.net/projects/commotion-manual/wiki/Detailed_TFTP_Instructions

How to Update an existing Commotion node:
https://code.commotionwireless.net/projects/commotion-manual/wiki/Updating_the_Commotion_software_on_your_router
