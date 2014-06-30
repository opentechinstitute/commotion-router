#!/bin/bash
cd $TEMP_DIR
echo "./configure is being run in `pwd`" 
git clone https://github.com/opentechinstitute/commotion-router.git
cd commotion-router
SRC_DIR="`pwd`/openwrt"
echo "As of the end of ./configure, we think the location of the openwrt makefile is: $SRC_DIR"
./setup.sh
cp /mnt/custom/buffalo-wzr-hp-ag300h/files/etc/config/network $SRC_DIR/files/etc/config/
cp /mnt/custom/buffalo-wzr-hp-ag300h/.config $SRC_DIR
