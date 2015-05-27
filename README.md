[![alt tag](http://img.shields.io/badge/maintainer-jheretic-red.svg)](https://github.com/jheretic)

Commotion-Router
===============
*This new, CMake-based build system only works for Barrier Breaker-based images, which are not yet fully functional. Use the 1.1 branch to use the old buildsystem for creation of Attitude Adjustment-based v1.1 images.*

Commotion is an open source “device-as-infrastructure” communication platform that integrates users’ existing cell phones, Wi-Fi enabled computers, and other wireless-capable devices to create community- and metro-scale, peer-to-peer communications networks.

Commotion software exists for multiple platforms; this repository contains the build system for the [OpenWRT](https://openwrt.org) router firmware distribution of the Commotion Wireless project. This repo builds the following other Commotion projects in order to create installation images for turning select wireless routers into Commotion nodes. It contains only the scripts and default files needed to download OpenWRT and add Commotion's packages to the OpenWRT build system. These scripts are written with [CMake](http://cmake.org) and wrap the [OpenWRT ImageBuilder](http://wiki.openwrt.org/doc/howto/obtain.firmware.generate) and [SDK] (http://wiki.openwrt.org/doc/howto/obtain.firmware.sdk). Those Commotion packages are defined in the packages directory of the Commotion Feed repo (https://github.com/opentechinstitute/commotion-feed.git). Package source code can be found in the repositories (PKG_SOURCE_URL) and branches (PKG_VERSION) specified in their respective Commotion Feed Makefiles.

If you would like to know more about setting up a mesh network check out the Commotion Construction Kit at https://commotionwireless.net/docs/cck

The Commotion Daemon
--------------------

https://github.com/opentechinstitute/commotiond.git

The commotion daemon is an embedded daemon and library that provides a common interface for managing wireless mesh networks. 

LuCI Commotion
--------------

https://github.com/opentechinstitute/luci-commotion

The Commotion [LuCI](http://luci.subsignal.org) web interface extensions provide an easy to understand interface that allows a new user to quickly configure a node to their needs. This repository contains multiple components:
* Commotion basic configuration menus
* Commotion LuCI theme
* Commotion local apps portal: The application suite allows for developers to easily advertise applications over a commotion mesh using mdns, users to easily find applications through the router app advertising interface, and node owners to easily manage and customize their application portals to better support community application support.
* Commotion debug helper: The debugging helper creates custom, downloadable informational debugging documents for offline debugging, or to send to network maintainers. Each of these new tools needs testing to find errors as well as to ensure their usability.
* Commotion dashboard helper: The dashboard helper reports statistics to an external dashboard.
* Commotion splash page and settings: A custom captive portal/splash screen and an interface for customizing it, built around nodogsplash (https://github.com/nodogsplash/nodogsplash).

Commotion Service Manager
-------------------------

https://github.com/opentechinstitute/commotion-service-manager

The service manager discovers and verifies announcements of applications hosted on the network, and loads them into the apps portal.

Libserval
---------

https://github.com/opentechinstitute/serval-dna

[Serval's](http://servalproject.org) key management library allows transparent encryption and authentication of messages.

How to use this repository to compile Commotion Router images
=============================================================
This repository contains a system of CMake files that download the OpenWRT ImageBuilder, extract, and run it with a pre-populated configuration. ImageBuilder is a standalone tool that creates OpenWRT firmware image files out of a set of package files. It supports automatic dependency resolution and downloading of packages, and can build images for many different target platforms.

Additionally, these CMake files can optionally build all of the Commotion Router [packages](https://github.com/opentechinstitute/commotion-feed) using the OpenWRT SDK, a pre-built cross-compiler toolchain for the OpenWRT Linux operating system.

In order to use the CMake files in this repository, you can run them like any other CMake project. You can use either the command-line interface or, if available, the CMake GUI.

Requirements
------------
* A modern Linux system.
* CMake >= v3.0.2.
* git
* zlib
* svn
* awk
* ccache
* gcc
* ncurses
* libssl
* xsltproc

On a Debian-based system, including Ubuntu or Mint, you can simply type
`sudo apt-get install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc cmake` to install the packages above. Additional packages may be required if you encounter errors during the build process (e.g., `sudo apt-get install libxml-parser-perl`).

Building on OSX is ill-advised, as such requires a large number of dependencies and, most difficultly, a case-sensitive filesystem. Here is [how to determine if you are](https://apple.stackexchange.com/questions/71357/how-to-check-if-my-hd-is-case-sensitive-or-not), but unless you installed OSX yourself and use no Adobe programs (they require case-insensitive), your filesystem is case-insensitive. It is likely quicker to configure a Linux virtual machine and use that instead. If you do have a case-sensitive filesystem, you can proceed, but [YMMV](https://en.wiktionary.org/wiki/YMMV).

With the command-line interface
-------------------------------
The Commotion Router buildsystem provides a number of options for configuring your build targets.

| Option | Type | Description | Default |
| ------ | ---- | ----------- | ------- |
| COMMOTION_VERSION | String | Branch of Commotion to build | master |
| COMMOTION_RELEASE | String | Commotion release nickname | grumpy_cat |
| DEBUG | Bool | Create verbose Makefile output | False |
| SKIP_MD5 | Bool | Skip MD5 checking of downloaded ImageBuilder | False |
| CONFIG | String | Commotion Router target | ubnt |
| BUILD_IMAGES | Bool | Toggle building of images | True |
| BUILD_PACKAGES | Bool | Toggle building of packages | True |
| USE_LOCAL | Bool | Use locally built packages when building images | False |
| JOBS | String | Number of parallel compile jobs | 2 |
| DL_DIR | Filepath | Custom download directory | CMAKE_CURRENT_BINARY_DIR |

The CONFIG value must correspond to the name of a directory under config/ inside the repository. See below in order to find out how to create new configurations. The Commotion version and release strings specified must correspond to the repository structure in http://downloads.commotionwireless.net/router/.

For example, to build an image with the default options, clone the repository and run the following inside.

```
mkdir build
cd build
cmake ..
make
```

The ImageBuilder will be downloaded and configured to for the ubnt target. *Resulting images will be located in build/bin*. To build for version 1.0 of release foo with target bar, with debugging turned on and MD5 checking off, you would run the following (this is just an example and will not complete):

```
mkdir build
cd build
cmake -DCOMMOTION_VERSION:String=1.0 -DCOMMOTION_RELEASE:String=foo -DCONFIG:String=bar -DDEBUG:Bool=True -DSKIP_MD5:Bool=True ..
make
```
With the cmake-gui
----------------------
You can build with the GUI similarly to above, except that all the configuration values will be present in the GUI.

```
mkdir build
cd build
cmake-gui ..
```

Select the options you want, then click "Configure" and then "Generate." After the GUI has generated the Makefiles, you can subsequently run `make`.

Create your own build configurations
------------------------------------
Specific build configurations are contained within the 'configs' directory. To create a new configuration, just create a directory with the desired configuration name. For instance, the existence of the 'configs/ubnt' directory will cause 'ubnt' to show up in the list of available configurations in cmake-gui, and 'ubnt' is what you would provide to cmake on the commandline for the CONFIG option.

A valid configuration directory contains its own CMakeLists.txt file that defines, at minimum, the variables TARGET, SUBTARGET, and PROFILE. Below is the contents of a valid 'configs/ubnt/CMakeLists.txt':

```
SET(TARGET "ar71xx" PARENT_SCOPE)
SET(SUBTARGET "generic" PARENT_SCOPE)
SET(PROFILE "UBNT" PARENT_SCOPE)
```

This is CMake syntax for setting the variables TARGET, SUBTARGET, and PROFILE to 'ar71xx', 'generic', and 'UBNT' respectively. 'PARENT\_SCOPE' is a necessary CMake option for making sure this information is available to the buildsystem. To learn more about what TARGET, SUBTARGET, and PROFILE mean, and how to figure out which ones to pick, see the [OpenWRT ImageBuilder documentation.](http://wiki.openwrt.org/doc/howto/obtain.firmware.generate)

Additionally, you may define a PACKAGES variable to add additional packages to this particular configuration. If you are adding more than one, it must be provided as a semicolon-delmited list. For instance, to add the packages 'foo' and 'bar':

```
SET(PACKAGES "foo;bar" PARENT_SCOPE)
```

You may remove packages instead by prepending the package name with a minus sign.

Optionally, the configuration may provide a 'files' directory as well. For example, you might have a directory 'configs/ubnt/files' which contains a file 'configs/ubnt/files/etc/hosts'. That file would be copied to '/etc/hosts' in the built image; any file or directory is copied directly into the root filesystem of the router image as the last step. This is useful for providing custom configuration files, and any file in here overwrites any equivalent default configuration files provided by the Commotion buildsystem or any packages.

Installation Instructions (Ubiquiti Devices): 
---------------------------------------------

http://commotionwireless.net/docs/cck/installing-configuring/install-ubiquiti-router

Install & Recover with TFTP (Ubiquiti Devices):
-----------------------------------------------

http://commotionwireless.net/docs/cck/installing-configuring/install-and-recover-tftp

Installation Instructions (Other Devices):
------------------------------------------

Specific installation instructions for non-Ubiquiti devices can be found in the [OpenWRT Table of Hardware](http://wiki.openwrt.org/toh/start)
