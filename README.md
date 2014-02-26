##Commotion Router

Commotion is an open source “device-as-infrastructure” communication platform that integrates users’ existing cell phones, Wi-Fi enabled computers, and other wireless-capable devices to create community- and metro-scale, peer-to-peer communications networks.

Commotion software exists for multiple platforms; this repository contains the build system for the OpenWRT router firmware distribution of the Commotion Wireless project. This repo builds the following other Commotion projects in order to create installation images for turning select wireless routers into Commotion nodes. It contains only the scripts and default files needed to download OpenWRT and add Commotion's packages to the OpenWRT build system. Those Commotion packages are defined in the packages directory of the Commotion Feed repo (https://github.com/opentechinstitute/commotion-feed.git). Package source code can be found in the repositories (PKG_SOURCE_URL) and branches (PKG_VERSION) specified in their respective Commotion Feed Makefiles.

If you would like to know more about setting up a mesh network check out the Commotion Construction Kit at https://commotionwireless.net/docs/cck

###The Commotion Daemon

https://github.com/opentechinstitute/commotiond.git

The commotion daemon is an embedded daemon and library that provides a common interface for managing wireless mesh networks. 

###LuCI Commotion

https://github.com/opentechinstitute/luci-commotion

The Commotion LuCI web interface extensions provide an easy to understand interface that allows a new user to quickly configure a node to their needs. 

###Commotion Theme

https://github.com/opentechinstitute/luci-theme-commotion

The Commotion OpenWRT theme for the web-interface on Commotion wireless routers.

###Commotion Application Portal

https://github.com/opentechinstitute/luci-commotion-apps

The application suite allows for developers to easily advertise applications over a commotion mesh using mdns, users to easily find applications through the router app advertising interface, and node owners to easily manage and customize their application portals to better support community application support. 

###Commotion Service Manager

https://github.com/opentechinstitute/commotion-service-manager

The service manager discovers and verifies announcements of applications hosted on the network, and loads them into the apps portal.

###Libserval

https://github.com/opentechinstitute/serval-dna

Serval's key management library allows transparent encryption and authentication of messages.

###Commotion Debug Helper

https://github.com/opentechinstitute/commotion-debug-helper

The debugging helper creates custom, downloadable informational debugging documents for offline debugging, or to send to network maintainers. Each of these new tools needs testing to find errors as well as to ensure their usability.

###Commotion Dashboard Helper

https://github.com/opentechinstitute/commotion-dashboard-helper

The dashboard helper reports statistics to an external dashboard. 

###Commotion Splash

https://github.com/opentechinstitute/luci-commotion-splash

A custom captive portal/splash screen and an interface for customizing it, built around nodogsplash (https://github.com/nodogsplash/nodogsplash).


##Build & Install
                                                         
How to create a Commotion image from source (the really really quick guide):

In the following commands, `text in this format` should be run from the command line.

Before you begin, you may need to install additional the following software:
* git
* svn
* ncurses
* zlib
* awk
* XML::Parser

On a Debian-based system, including Ubuntu or Mint, you can simply type
`sudo apt-get install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc`. Additional packages may be required if you encounter errors during the build process (e.g., `sudo apt-get install libxml-parser-perl`).

1. `git clone https://github.com/opentechinstitute/commotion-openwrt.git`

2. `cd commotion-openwrt/`

3. (Optional) By default, Commotion-Router is configured to include the most recent code, which may not yet be thoroughly tested. To build a specific Commotion release (e.g., Commotion 1.1), you must specify a branch or tag. For example: `git checkout 1.1`.

4. Run `./setup.sh` to set Commotion's defaults and add Commotion's packages as an OpenWRT feed. This step will require network access.

5. `cd openwrt/`

6. (Optional) By default, Commotion-Router will build images for Ubiquiti devices. To choose a different router or customize your installed packages `make menuconfig`.

7. (Optional) To build for a different router, select your device from `Target Profile (Ubiquiti Products)` in menuconfig. You may also choose a different chipset using the `Target System` option, but chipsets other than AR7xxx/AR9xxx are not well supported. If you can't find your router in the list, use the [OpenWRT Table of Hardware](http://wiki.openwrt.org/toh/start) to make sure it is supported by OpenWRT. Note that the default Commotion-Router image is 5.4MB, so your router will need a minimum of 6MB of flash space.

8. (Optional) To add or remove additional languages, while in menuconfig, select `Commotion` then `Translations` and choose from available options. 

9. `make V=99`. This step will take a very long time and will require network access.

10. `cd bin/`. Your router images will be .bin files stored in a directory named after your wireless chip. For example, a default Commotion build for a Ubiquiti Nanostation would be `ar71xx/openwrt-ar71xx-generic-ubnt-nano-m-squashfs-factory.bin`


####Installation Instructions (Ubiquiti Devices):

http://commotionwireless.net/docs/cck/installing-configuring/install-ubiquiti-router

####Install & Recover with TFTP (Ubiquiti Devices):

http://commotionwireless.net/docs/cck/installing-configuring/install-and-recover-tftp

####Installation Instructions (Other Devices):

Specific installation instructions for non-Ubiquiti devices can be found in the [OpenWRT Table of Hardware](http://wiki.openwrt.org/toh/start)
