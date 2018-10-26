#
# Copyright (c) 2018 Tony Ambardar
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=speedtest
PKG_VERSION:=0.9
PKG_RELEASE:=4
PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Tony Ambardar <itugrok@yahoo.com>, Rich Brown <rich.brown@blueberryhillsoftware.com>

include $(INCLUDE_DIR)/package.mk

define Package/speedtest
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Script to measure the performance of your network and router
	DEPENDS:=+netperf
	PKGARCH:=all
endef

define Package/speedtest/description
Script to measure the performance of your network and router.

Please see https://github.com/openwrt/packages/blob/master/net/speedtest/files/README.md for further information.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/speedtest/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/speedtest.sh $(1)/usr/bin/
endef

$(eval $(call BuildPackage,speedtest))
