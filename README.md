[![alt tag](http://img.shields.io/badge/maintainer-jheretic-red.svg)](https://github.com/jheretic)

Commotion-Build
===============
This is a system for building [Commotion Router](https://github.com/opentechinstitute/commotion-router) images. It is written with [CMake](http://cmake.org). Commotion-Build wraps the [OpenWRT ImageBuilder](http://wiki.openwrt.org/doc/howto/obtain.firmware.generate) and is part of the [Commotion Project](https://commotionwireless.net).

Requirements
============
* A modern Linux system.
* CMake >= v3.0.2.

How to use
==========
Commotion-Build is a system of CMake files that downloads the OpenWRT ImageBuilder, extracts, and runs it with a pre-populated configuration. ImageBuilder is a standalone tool that creates OpenWRT firmware image files out of a set of package files. It supports automatic dependency resolution and downloading of packages, and can build images for many different target platforms.

In order to use Commotion-Build, you can run it like any other CMake project. You can use either the command-line interface or, if available, the CMake GUI.

With the command-line interface
-------------------------------
Commotion-Build provides a number of options for configuring your build targets.

| Option | Type | Description | Default |
| ------ | ---- | ----------- | ------- |
| COMMOTION_VERSION | String | Commotion version number | 1.1 |
| COMMOTION_RELEASE | String | Commotion release nickname | grumpy_cat |
| DEBUG | Bool | Create verbose Makefile output | False |
| SKIP_MD5 | Bool | Skip MD5 checking of downloaded ImageBuilder | False |
| CONFIG | String | Commotion Router target | ubnt |

The CONFIG value must correspond to the name of a directory under config/ inside the repository. See below in order to find out how to create new configurations. The Commotion version and release strings specified must correspond to the repository structure in http://downloads.commotionwireless.net/router/.

For example, to build an image with the default options, clone the repository and run the following inside.

```
mkdir build
cd build
cmake ..
make install
```

The ImageBuilder will be downloaded and configured to for the ubnt target. Resulting images will be located in build/bin. To build for version 1.0 of release foo with target bar, with debugging turned on and MD5 checking off, you would run the following (this is just an example and will not complete):

```
mkdir build
cd build
cmake -DCOMMOTION_VERSION:String=1.0 -DCOMMOTION_RELEASE:String=foo -DCONFIG:String=bar -DDEBUG:Bool=True -DSKIP_MD5:Bool=True ..
make install
```
With the commotion-gui
----------------------
You can build with the GUI similarly to above, except that all the configuration values will be present in the GUI.

```
mkdir build
cd build
cmake-gui ..
```

Select the options you want, then click "Configure" and then "Generate." After the GUI has generated the Makefiles, you can subsequently run `make install`.

Create your own build configurations
====================================
TODO
