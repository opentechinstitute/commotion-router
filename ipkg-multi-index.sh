#!/usr/bin/env bash
##################################################################################################
# FILE: ipkg-multi-index.sh
# DESCRIPTION: Adapted from ipkg-make-index.sh, build multiple ipkg indexes.
# 
# Copyright (c) 2014, Josh King
#
# This file is part of Commotion-Router.
# 
# Commotion-Router is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Commotion-Router is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Commotion-Router.  If not, see <http://www.gnu.org/licenses/>.
##################################################################################################
set -e

if [ -z $1 ] || [ ! -d $1 ]; then
	echo "Usage: ipkg-make-index <package_directory>" >&2
	exit 1
fi

cd "$1" 2>/dev/null || exit 1
base="`pwd -P`"

echo "base: $base"

which md5sum >/dev/null 2>&1 || alias md5sum=md5

for pkg_dir in `ls "$base"`; do
  [[ -d "$base/$pkg_dir" ]] && cd "$base/$pkg_dir" || continue
  [[ -f "$base/$pkg_dir/Packages" ]] && rm "$base/$pkg_dir/Packages"
  [[ -f "$base/$pkg_dir/Packages.gz" ]] && rm "$base/$pkg_dir/Packages.gz"
  for pkg in `find . -name '*.ipk' | sort`; do
  	name="${pkg##*/}"
  	name="${name%%_*}"
  	[[ "$name" = "kernel" ]] && continue
  	[[ "$name" = "libc" ]] && continue
  	echo "Generating index for package $pkg" >&2
  	file_size=$(ls -l $pkg | awk '{print $5}')
  	md5sum=$(md5sum $pkg | awk '{print $1}')
  	sha256sum=$(openssl dgst -sha256 $pkg | awk '{print $2}')
  	# Take pains to make variable value sed-safe
  	sed_safe_pkg=`echo $pkg | sed -e 's/^\.\///g' -e 's/\\//\\\\\\//g'`
  	tar -xzOf $pkg ./control.tar.gz | tar xzOf - ./control | sed -e "s/^Description:/Filename: $sed_safe_pkg\\
  Size: $file_size\\
  MD5Sum: $md5sum\\
  SHA256sum: $sha256sum\\
  Description:/" 2>&1 >> ./Packages
  	echo "" >> ./Packages
  done
  [[ -f ./Packages ]] && gzip -9c ./Packages > ./Packages.gz
done
