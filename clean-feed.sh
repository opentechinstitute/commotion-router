#!/usr/bin/env bash
##################################################################################################
# FILE: clean-feed.sh
# DESCRIPTION: Run clean target on all Makefiles in a feed directory.
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
	echo "Usage (in SDK base directory): clean-feed.sh <feed directory>" >&2
	exit 1
fi

if [ -z "$1/Makefile" ]; then
  echo "No Makefile found. Are you in the base directory of the OpenWRT SDK?"
  exit 1
fi

feed=$1

for pkg in `ls "$feed"`; do
  [[ -d "$feed/$pkg" ]] && make package/$pkg/clean V=s || continue
done
