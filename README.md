[![alt tag](http://img.shields.io/badge/maintainer-jheretic-red.svg)](https://github.com/jheretic)

Commotion-Router
===============
This is a system for building [Commotion Router](https://commotionwireless.net) images. It is written with [CMake](http://cmake.org). Commotion-Router wraps the [OpenWRT](https://openwrt.org) [ImageBuilder](http://wiki.openwrt.org/doc/howto/obtain.firmware.generate) and [SDK] (http://wiki.openwrt.org/doc/howto/obtain.firmware.sdk) and is part of the [Commotion Project](https://commotionwireless.net).

Requirements
============
* A modern Linux system.
* CMake >= v3.0.2.

How to use
==========
This repository contains a system of CMake files that download the OpenWRT ImageBuilder, extract, and run it with a pre-populated configuration. ImageBuilder is a standalone tool that creates OpenWRT firmware image files out of a set of package files. It supports automatic dependency resolution and downloading of packages, and can build images for many different target platforms.

Additionally, these CMake files can optionally build all of the Commotion Router [packages](https://github.com/opentechinstitute/commotion-feed) using the OpenWRT SDK, a pre-built cross-compiler toolchain for the OpenWRT Linux operating system.

In order to use the CMake files in this repository, you can run them like any other CMake project. You can use either the command-line interface or, if available, the CMake GUI.

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

The ImageBuilder will be downloaded and configured to for the ubnt target. Resulting images will be located in build/bin. To build for version 1.0 of release foo with target bar, with debugging turned on and MD5 checking off, you would run the following (this is just an example and will not complete):

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
====================================
TODO
