#!/bin/bash

print_usage() {
  cat << EOF
Commotion Upgrade Builder
https://commotionwireless.net

Usage:
	upgrade-builder.sh prepare [-v] -d <dir> -o <out> [-s <key> -b <sock> [-k <keyring>]]
    or:
	upgrade-builder.sh build [-v] -p <package> -d <dir>
General options:
    -v			Verbose
Prepare options:
    -d <dir>		Upgrade script directory that includes a manifest
    -s <key>		Serval public key (SID) used for signing manifest file
    -b <socket>		Management socket for running commotiond instance
    -k <keyring>	Serval keyring file containing signing key
    -o <outfile>	Package file to build
Build options:
    -p <package>	Previously built package file
    -d <dir>		Directory of images to convert into upgrade bundles
    -r <release>	Release string to add to bundle filename
    
Run the prepare command on a directory containing upgrade scripts and a manifest, then run
the build command on the previously created package and an image file to produce an upgrade
bundle for the Commotion router firmware.
EOF
}

fail() {
  print_usage
  exit 1
}

prepare() {
  [[ -z "$DIR" || -z "$OUTFILE" || \
    (-n "$SID" && -z "$SOCK") || \
    (-z "$SID" && -n "$SOCK") ]] && fail
  
  [[ ! -d "$DIR" ]] && {
    echo "Directory $DIR does not exist" >&2
    exit 1
  }
  
  [[ ! -f "$DIR/manifest" ]] && {
    echo "Upgrades directory $DIR is missing manifest" >&2
    exit 1
  }
  
  [[ -n "$SID" ]] && {
    SIGNATURE="$(commotion -b "$SOCK" serval-crypto sign $SID "$(cat "$DIR/manifest")" ${KEYRING:+keyring="$KEYRING"} |grep signature |grep -o "[0-9A-F]\{128\}")"
    [[ $? != 0 ]] && {
      echo "Failed to sign upgrade manifest"
      exit 1
    }
    echo -n "$SIGNATURE" > "$DIR/manifest.asc"
  }
  
  [[ -f "$OUTFILE" ]] && rm -f "$OUTFILE"
  cd "$DIR" && tar zc${VERBOSE:+v}f "$OUTFILE" . || exit 1
  
  [[ -n "$VERBOSE" ]] && echo "Package $OUTFILE successfully built"
}

build() {
  [[ -z "$PACKAGE" || -z "$IMAGE_DIR" ]] && fail
  
  [[ ! -d "$IMAGE_DIR" ]] && {
    echo "Directory $IMAGE_DIR does not exist" >&2
    exit 1
  }

  [[ ! -e "$PACKAGE" ]] && {
    echo "File $PACKAGE does not exist" >&2
    exit 1
  }
  
  SIZE=$(ls -l "$PACKAGE" |cut -d' ' -f5)
  BYTE_STRING=$(printf %08X $SIZE |awk 'BEGIN { FIELDWIDTHS="2 2 2 2" } { print "\\x"$1"\\x"$2"\\x"$3"\\x"$4 }')
  
  cd "$IMAGE_DIR"
  for IMAGE in $(ls "$IMAGE_DIR"/*-{sysupgrade,factory}.bin); do
    # append tarball to image
    cat "$PACKAGE" >> "$IMAGE"

    # append 4 byte tarball size to image
    printf "$BYTE_STRING" >> "$IMAGE"

    # append magic bytes to image
    printf "\xc0\xfe\xba\xbe" >> "$IMAGE"

    # rename image
    echo `basename $IMAGE` | sed -n "s/\(^openwrt-\)\(.*\)\(\.bin$\)/mv "\\1\\2\\3" "commotion-${RELEASE}-\\2.bundle"/p" | sh

    [[ -n "$VERBOSE" ]] && echo "Image $IMAGE successfully converted into upgrade bundle"
  done
}

ACTION="$1"
shift
if [[ "$ACTION" == "prepare" ]]; then
  while getopts ":d:s:b:k:o:v" opt; do
    case $opt in
      v) VERBOSE=1;;
      d) DIR="$OPTARG";;
      s) SID="$OPTARG";;
      b) SOCK="$OPTARG";;
      k) KEYRING="$OPTARG";;
      o) OUTFILE="$OPTARG";;
      \?) 
	echo "Invalid option -$OPTARG" >&2
	fail
	;;
      :) echo "Option -$OPTARG requires and argument" >&2
	fail
	;;
    esac
  done
  prepare
elif [[ "$ACTION" == "build" ]]; then
  while getopts ":p:d:r:v" opt; do
    case $opt in
      v) VERBOSE=1;;
      p) PACKAGE="$OPTARG";;
      d) IMAGE_DIR="$OPTARG";;
      r) RELEASE="$OPTARG";;
      \?) 
	echo "Invalid option -$OPTARG" >&2
	fail
	;;
      :) echo "Option -$OPTARG requires and argument" >&2
	fail
	;;
    esac
  done
  build
else
  fail
fi
