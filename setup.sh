#!/bin/sh

svn co svn://svn.openwrt.org/openwrt/branches/attitude_adjustment openwrt || exit 1

cd openwrt

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

# Patch AR71XX makefile so image can be flashed through the AirOS web interface
sed -i s/'$(eval $(call SingleProfile,UBNTXM,$(fs_64k),UBNTUNIFI,ubnt-unifi,UBNT-UF,ttyS0,115200,XM,XM,ar7240))'/'$(eval $(call SingleProfile,UBNTXM,$(fs_64k),UBNTUNIFI,ubnt-unifi,UBNT-UF,ttyS0,115200,XM,UBNTXM,ar7240))'/ openwrt/target/linux/ar71xx/image/Makefile

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Commotion OpenWrt is prepared. To build the firmware, type:"
echo " cd openwrt"
echo " make menuconfig #If you wish to add or change packages."
echo " make V=99"
echo " Please make use of the DR1rc wiki page:"
echo " https://code.commotionwireless.net/projects/commotion/wiki/AttitudeAdjustmentBuild"

