#!/bin/sh

svn co -r 31639 svn://svn.openwrt.org/openwrt/trunk openwrt || exit 1

cd openwrt
make defconfig
[ ! -e .config ] && cp -v ../config .config
[ ! -e .config.old ] && cp -v ../config .config.old
[ ! -e feeds.conf ] && cp -v feeds.conf.default feeds.conf
[ ! -e files ] && mkdir files
[ ! -e dl ] && mkdir ../dl && ln -sf ../dl dl
cp -rf -v ../default-files/* files/
if ! grep -q commotion feeds.conf; then
    echo "adding commotion package feed..."
    echo "src-link commotion ../../commotionfeed" >> feeds.conf
fi

scripts/feeds update -a
scripts/feeds install -a
for i in $(ls ../commotionfeed/); do scripts/feeds install $i; done

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Commotion OpenWrt is prepared. To build the firmware, type:"
echo " cd openwrt"
echo " make menuconfig #If you wish to add or change packages."
echo " make V=99"
