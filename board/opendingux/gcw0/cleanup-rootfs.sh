#!/bin/sh

TARGET_DIR=$1

# Remove binutils executables we don't use
for i in ar as ld ld.bfd nm objcopy ranlib strip ; do
	rm -f ${TARGET_DIR}/usr/bin/$i
done
rm -rf ${TARGET_DIR}/usr/mipsel-gcw0-linux-uclibc

# We use xinetd, so no need for a startup script for the SSH daemons.
rm -f ${TARGET_DIR}/etc/init.d/S50sshd
rm -f ${TARGET_DIR}/etc/init.d/S50dropbear

# The NTP daemon is started in the /etc/network/if-up.d/ntpd
# script and stopped in /etc/network/if-post-down.d/ntpd.
rm -f ${TARGET_DIR}/etc/init.d/S49ntp

# The Avahi daemon is started in the /etc/network/if-up.d/avahi
# script and stopped in /etc/network/if-post-down.d/avahi
rm -f ${TARGET_DIR}/etc/init.d/S50avahi

# Cleanup DRI drivers
(
	cd ${TARGET_DIR}/usr/lib/dri
	[ -f ingenic-drm_dri.so ] && mv ingenic-drm_dri.so libgallium_dri.so
	find . ! -name libgallium_dri.so -type f -exec rm -f {} +
	ln -s libgallium_dri.so ingenic-drm_dri.so
	ln -s libgallium_dri.so etnaviv_dri.so
)

# Remove the parts from udev's hwdb that we don't need
rm -rf ${TARGET_DIR}/etc/udev/hwdb.d/20-pci-vendor-model.hwdb \
	${TARGET_DIR}/etc/udev/hwdb.d/20-pci-classes.hwdb \
	${TARGET_DIR}/etc/udev/hwdb.d/20-sdio-vendor-model.hwdb \
	${TARGET_DIR}/etc/udev/hwdb.d/20-sdio-classes.hwdb \
	${TARGET_DIR}/etc/udev/hwdb.d/20-OUI.hwdb \
	${TARGET_DIR}/etc/udev/hwdb.d/20-acpi-vendor.hwdb

# Remove locales
rm -rf ${TARGET_DIR}/usr/share/locale

# Clear 'dependency_libs' key from libtool archives.
# Linux supports dependencies between dynamic libraries; libtool trying to keep
# track of them as well causes problems when it inevitably gets it wrong.
# And these flags are not useful for static linking either, since "-l" will
# pick up a dynamic library if it is available, which it likely is in our case.
find ${HOST_DIR} -name '*.la' -exec sed -i "/dependency_libs=/s/'.*'/''/" {} \;

# Remove libtool archives backup files generated by *_INSTALL_STAGING_CMDS.
find ${HOST_DIR} -name '*.la~' -exec rm {} \;

# Remove all the stuff that Mono installs and that we don't need
rm -rf ${TARGET_DIR}/usr/lib/mono/mono-configuration-crypto
rm -rf ${TARGET_DIR}/usr/lib/mono/monodoc
rm -rf ${TARGET_DIR}/usr/lib/mono/xbuild
rm -rf ${TARGET_DIR}/usr/lib/mono/xbuild-frameworks
rm -rf ${TARGET_DIR}/etc/mono/2.0
rm -rf ${TARGET_DIR}/etc/mono/4.0
for i in ${TARGET_DIR}/usr/lib/mono/4.5/* ${TARGET_DIR}/usr/lib/mono/gac/* ; do
	FILE=`basename $i`
	case "$FILE" in
		System.Core | System | System.Security | System.Xml | System.Configuration)
			;;
		System.Core.dll | System.dll | System.Security.dll | System.Xml.dll | System.Configuration.dll | mscorlib.dll)
			;;
		*)
			rm -rf $i
			;;
	esac
done

# Create cmake helpers
echo '#!/bin/sh\n\nexec cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_TOOLCHAIN_FILE=`dirname $0`/../share/buildroot/toolchainfile.cmake $*' > ${HOST_DIR}/usr/bin/mipsel-gcw0-linux-uclibc-cmake
chmod +x ${HOST_DIR}/usr/bin/mipsel-gcw0-linux-uclibc-cmake
ln -sf mipsel-gcw0-linux-uclibc-cmake ${HOST_DIR}/usr/bin/mipsel-linux-cmake

# Create ccmake helpers
echo '#!/bin/sh\n\nexec ccmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_TOOLCHAIN_FILE=`dirname $0`/../share/buildroot/toolchainfile.cmake $*' > ${HOST_DIR}/usr/bin/mipsel-gcw0-linux-uclibc-ccmake
chmod +x ${HOST_DIR}/usr/bin/mipsel-gcw0-linux-uclibc-ccmake
ln -sf mipsel-gcw0-linux-uclibc-ccmake ${HOST_DIR}/usr/bin/mipsel-linux-ccmake

# Remove modules installed in target dir
rm -rf ${TARGET_DIR}/lib/modules/*

# Create modules filesystem
(
	cd ${BUILD_DIR}/linux-custom
	./create_modules_fs.sh
	mv modules.squashfs ${BINARIES_DIR}/modules.squashfs
)
