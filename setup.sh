#!/bin/sh

svn co -r 28680 svn://svn.openwrt.org/openwrt/branches/backfire openwrt || exit 1

cd openwrt
[ ! -e .config ] && cp -v ../config .config
[ ! -e feeds.conf ] && cp -v feeds.conf.default feeds.conf
[ ! -e files ] && mkdir files
cp -rf -v ../default-files/* files/
if ! grep -q commotion feeds.conf; then
    echo "adding commotion package feed..."
    echo "src-link commotion ../../commotionfeed" >> feeds.conf
fi

scripts/feeds update
scripts/feeds install commotionbase

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Commotion OpenWrt is prepared. To build the firmware, type:"
echo " cd openwrt"
echo " make menuconfig"
echo " make V=99"
