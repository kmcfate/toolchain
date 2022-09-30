################################################################################
#
# wireless_tools
#
################################################################################

WIRELESS_TOOLS_VERSION_MAJOR = 30
WIRELESS_TOOLS_VERSION = $(WIRELESS_TOOLS_VERSION_MAJOR).pre9
WIRELESS_TOOLS_SITE = https://hewlettpackard.github.io/wireless-tools
WIRELESS_TOOLS_SOURCE = wireless_tools.$(WIRELESS_TOOLS_VERSION).tar.gz
WIRELESS_TOOLS_LICENSE = GPLv2
WIRELESS_TOOLS_LICENSE_FILES = COPYING
WIRELESS_TOOLS_INSTALL_STAGING = YES

WIRELESS_TOOLS_BUILD_TARGETS = iwmulticall
WIRELESS_TOOLS_INSTALL_TARGETS = install-iwmulticall


ifeq ($(BR2_PACKAGE_WIRELESS_TOOLS_LIB),y)
	WIRELESS_TOOLS_BUILD_TARGETS += libiw.so.$(WIRELESS_TOOLS_VERSION_MAJOR)
	WIRELESS_TOOLS_INSTALL_TARGETS += install-dynamic

define WIRELESS_TOOLS_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) PREFIX="$(STAGING_DIR)" LDCONFIG=/bin/true install-dynamic
	$(MAKE) -C $(@D) PREFIX="$(STAGING_DIR)/usr" install-hdr
endef

endif

define WIRELESS_TOOLS_BUILD_CMDS
	$(MAKE) -C $(@D) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
		$(WIRELESS_TOOLS_BUILD_TARGETS)
endef

define WIRELESS_TOOLS_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) PREFIX="$(TARGET_DIR)" LDCONFIG=/bin/true $(WIRELESS_TOOLS_INSTALL_TARGETS)
	$(MAKE) -C $(@D) INSTALL_MAN="$(TARGET_DIR)/usr/share/man" install-man
endef

$(eval $(generic-package))
