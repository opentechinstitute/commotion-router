# Copyright (C) 2010 Commotion
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
include $(TOPDIR)/rules.mk

PKG_NAME:=commotionbase
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/commotionbase
  SECTION:=commotion
  CATEGORY:=Commotion
  TITLE:=Commotion Base System
  DEPENDS:=+dnsmasq +olsrd +patch
  URL:=http://commotionwireless.net
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/commotionbase/description
  Commotion rapid-deployment infrastructure
endef

define Package/commotionbase/install
	$(CP) ./files/* $(1)/
	$(SED) 's,$$$$R,$(REVISION),g' $(1)/usr/share/commotion/files/banner
endef

define Package/commotionbase/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	( . /etc/uci-defaults/commotionbase ) && rm -f /etc/uci-defaults/commotionbase
}
endef

$(eval $(call BuildPackage,commotionbase))
