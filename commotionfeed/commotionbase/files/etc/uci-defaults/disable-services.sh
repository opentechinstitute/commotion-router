#!/bin/sh

# disable services we don't want enabled on first boot
[ -f "/etc/init.d/usb" ] && { \
  /etc/init.d/usb disable
  /etc/init.d/usb stop
}

