#!/bin/sh

#git clone git://git.openwrt.org/12.09/openwrt.git
svn co svn://svn.openwrt.org/openwrt/tags/attitude_adjustment_12.09/ openwrt

cd openwrt
patch -p1 < ../patches/unifi.patch

[ ! -e feeds.conf ] && cp -v ../feeds.conf feeds.conf
[ ! -e files ] && mkdir files
cp -rf -v ../default-files/* files/
if ! grep -q commotion feeds.conf; then
    echo "adding commotion package feed..."
    echo "src-git commotion git://github.com/opentechinstitute/commotion-feed.git" >> feeds.conf
fi

scripts/feeds update -a
scripts/feeds install -a
scripts/feeds uninstall olsrd libldns
scripts/feeds install -p commotion olsrd libldns

# Copy in Commotion-specific patches
cp -v ../patches/910-fix-out-of-bounds-index.patch feeds/packages/utils/collectd/patches/
cp -v ../config .config

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Commotion OpenWrt is prepared. To build the firmware, type:"
echo " cd openwrt"
echo " make menuconfig #If you wish to add or change packages."
echo " make V=99"
