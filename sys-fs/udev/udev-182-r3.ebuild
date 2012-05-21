# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/udev/udev-182-r3.ebuild,v 1.5 2012/05/04 19:09:16 jdhore Exp $

EAPI=4

KV_min=2.6.34
# patchversion=1
udev_rules_md5=ebc2cf422aa9e46cf7d9a555670412ba

EGIT_REPO_URI="git://git.kernel.org/pub/scm/linux/hotplug/udev.git"

[[ ${PV} == "9999" ]] && vcs="git-2 autotools"
inherit ${vcs} eutils flag-o-matic multilib toolchain-funcs linux-info systemd libtool

if [[ ${PV} != "9999" ]]
then
	KEYWORDS="~*"
	SRC_URI="mirror://kernel/linux/utils/kernel/hotplug/${P}.tar.bz2"
	if [[ -n "${patchversion}" ]]
	then
		patchset=${P}-patchset-${patchversion}
		SRC_URI="${SRC_URI} mirror://gentoo/${patchset}.tar.bz2"
	fi
fi

DESCRIPTION="Linux dynamic and persistent device naming support (aka userspace devfs)"
HOMEPAGE="http://www.kernel.org/pub/linux/utils/kernel/hotplug/udev/udev.html http://git.kernel.org/?p=linux/hotplug/udev.git;a=summary"

LICENSE="GPL-2"
SLOT="0"
IUSE="build selinux debug +rule_generator hwdb gudev introspection
	keymap floppy doc static-libs +openrc"

COMMON_DEPEND="selinux? ( sys-libs/libselinux )
	gudev? ( dev-libs/glib:2 )
	introspection? ( dev-libs/gobject-introspection )
	>=sys-apps/kmod-5
	>=sys-apps/util-linux-2.20
	!<sys-libs/glibc-2.10"

DEPEND="${COMMON_DEPEND}
	keymap? ( dev-util/gperf )
	virtual/pkgconfig
	virtual/os-headers
	!<sys-kernel/linux-headers-2.6.34"

if [[ $PV == "9999" ]]
then
	RESTRICT="test? ( userpriv )"
	IUSE="${IUSE} test"
	DEPEND="${DEPEND}
		dev-util/gtk-doc
		test? ( app-text/tree )"
else
	DEPEND="${DEPEND}
	doc? ( dev-util/gtk-doc )"
fi

RDEPEND="${COMMON_DEPEND}
	hwdb? ( sys-apps/hwids )
	openrc? ( >=sys-fs/udev-init-scripts-10
		!<sys-apps/openrc-0.9.9 )
	!sys-apps/coldplug
	!<sys-fs/lvm2-2.02.45
	!sys-fs/device-mapper
	!<sys-fs/udev-init-scripts-10
	!<sys-kernel/dracut-017-r1
	!<sys-kernel/genkernel-3.4.25"

udev_check_KV()
{
	if kernel_is lt ${KV_min//./ }
	then
		return 1
	fi
	return 0
}

pkg_setup()
{
	# required kernel options
	CONFIG_CHECK="~BLK_DEV_BSG ~DEVTMPFS ~HOTPLUG ~INOTIFY_USER ~NET ~PROC_FS
		~SIGNALFD ~SYSFS
		~!IDE ~!SYSFS_DEPRECATED ~!SYSFS_DEPRECATED_V2"

	linux-info_pkg_setup

	# always print kernel version requirements
	ewarn
	ewarn "${P} does not support Linux kernel before version ${KV_min}!"

	if ! udev_check_KV
	then
		eerror "Your kernel version (${KV_FULL}) is too old to run ${P}"
	fi

	KV_FULL_SRC=${KV_FULL}
	get_running_version
	if ! udev_check_KV
	then
		eerror
		eerror "udev cannot be restarted after emerging,"
		eerror "as your running kernel version (${KV_FULL}) is too old."
		eerror "You really need to use a newer kernel after a reboot!"
		NO_RESTART=1
	fi
}

src_prepare()
{
	# backport some patches
	if [[ -n "${patchset}" ]]
	then
		EPATCH_SOURCE="${WORKDIR}/${patchset}" EPATCH_SUFFIX="patch" \
			EPATCH_FORCE="yes" epatch
	fi

	# change rules back to group uucp instead of dialout for now
	sed -e 's/GROUP="dialout"/GROUP="uucp"/' \
		-i rules/*.rules \
	|| die "failed to change group dialout to uucp"

	if [ ! -e configure ]
	then
		gtkdocize --copy || die "gtkdocize failed"
		eautoreconf
	else
		# Make sure there are no sudden changes to upstream rules file
		# (more for my own needs than anything else ...)
		MD5=$(md5sum < "${S}/rules/50-udev-default.rules")
		MD5=${MD5/  -/}
		if [[ ${MD5} != ${udev_rules_md5} ]]
		then
			eerror "50-udev-default.rules has been updated, please validate!"
			eerror "md5sum: ${MD5}"
			die "50-udev-default.rules has been updated, please validate!"
		fi
		elibtoolize
	fi
}

src_configure()
{
	filter-flags -fprefetch-loop-arrays
	econf \
		--with-rootprefix=/ \
		--libdir=/usr/$(get_libdir) \
		--libexecdir=/lib \
		$(use_enable static-libs static) \
		$(use_with selinux) \
		$(use_enable debug) \
		$(use_enable rule_generator) \
		--with-pci-ids-path=/usr/share/misc/pci.ids \
		--with-usb-ids-path=/usr/share/misc/usb.ids \
		$(use_enable gudev) \
		$(use_enable introspection) \
		$(use_enable keymap) \
		$(use_enable floppy) \
		$(use_enable doc gtk-doc) \
		"$(systemd_with_unitdir)" \
		--docdir=/usr/share/doc/${PF} \
		--with-html-dir=/usr/share/doc/${PF}/html
}

src_install()
{
	emake DESTDIR="${D}" install

	find "${ED}" -type f -name '*.la' -exec rm -f {} +

	dodoc ChangeLog NEWS README TODO
	use keymap && dodoc src/keymap/README.keymap.txt

	# udevadm is now in /usr/bin.
	dosym /usr/bin/udevadm /sbin/udevadm

	# create symlinks for these utilities to /sbin
	# where multipath-tools expect them to be (Bug #168588)
	dosym /lib/udev/scsi_id /sbin/scsi_id

	# Now install rules
	insinto /lib/udev/rules.d
	doins "${FILESDIR}"/40-gentoo.rules
}

pkg_preinst()
{
	local htmldir
	for htmldir in gudev libudev; do
		if [[ -d ${ROOT}usr/share/gtk-doc/html/${htmldir} ]]; then
			rm -rf "${ROOT}"usr/share/gtk-doc/html/${htmldir}
		fi
		if [[ -d ${D}/usr/share/doc/${PF}/html/${htmldir} ]]; then
			dosym /usr/share/doc/${PF}/html/${htmldir} \
				/usr/share/gtk-doc/html/${htmldir}
		fi
	done
}

# 19 Nov 2008
fix_old_persistent_net_rules()
{
	local rules="${ROOT}"/etc/udev/rules.d/70-persistent-net.rules
	[[ -f ${rules} ]] || return

	elog
	elog "Updating persistent-net rules file"

	# Change ATTRS to ATTR matches, Bug #246927
	sed -i -e 's/ATTRS{/ATTR{/g' "${rules}"

	# Add KERNEL matches if missing, Bug #246849
	sed -ri \
		-e '/KERNEL/ ! { s/NAME="(eth|wlan|ath)([0-9]+)"/KERNEL=="\1*", NAME="\1\2"/}' \
		"${rules}"
}

# See Bug #129204 for a discussion about restarting udevd
restart_udevd()
{
	if [[ ${NO_RESTART} = "1" ]]
	then
		ewarn "Not restarting udevd, as your kernel is too old!"
		return
	fi

	# need to merge to our system
	[[ ${ROOT} = / ]] || return

	# check if root of init-process is identical to ours (not in chroot)
	[[ -r /proc/1/root && /proc/1/root/ -ef /proc/self/root/ ]] || return

	# abort if there is no udevd running
	[[ -n $(pidof udevd) ]] || return

	# abort if no /run/udev exists
	[[ -e /run/udev ]] || return

	elog
	elog "restarting udevd now."

	killall -15 udevd &>/dev/null
	sleep 1
	killall -9 udevd &>/dev/null

	/lib/udev/udevd --daemon
	sleep 3
	if [[ ! -n $(pidof udevd) ]]
	then
		eerror "FATAL: udev died, please check your kernel is"
		eerror "new enough and configured correctly for ${P}."
		eerror
		eerror "Please have a look at this before rebooting."
		eerror "If in doubt, please downgrade udev back to your old version"
	fi
}

# This function determines if a directory is a mount point.
# It was lifted from dracut.
ismounted()
{
	while read a m a; do
		[ "$m" = "$1" ] && return 0
	done < "${ROOT}"/proc/mounts
	return 1
}

pkg_postinst()
{
	mkdir -p "${ROOT}"/run
	fix_old_persistent_net_rules

	# "losetup -f" is confused if there is an empty /dev/loop/, Bug #338766
	# So try to remove it here (will only work if empty).
	rmdir "${ROOT}"/dev/loop 2>/dev/null
	if [[ -d "${ROOT}"/dev/loop ]]
	then
		ewarn "Please make sure your remove /dev/loop,"
		ewarn "else losetup may be confused when looking for unused devices."
	fi

	restart_udevd

	# people want reminders, I'll give them reminders.  Odds are they will
	# just ignore them anyway...

	# Removing some device-nodes we thought we need some time ago, 25 Jan 2007
	if [[ -d ${ROOT}/lib/udev/devices ]]
	then
		rm -f "${ROOT}"/lib/udev/devices/{null,zero,console,urandom}
	fi

	# Try to remove /etc/dev.d as that is obsolete, 23 Apr 2007
	if [[ -d ${ROOT}/etc/dev.d ]]
	then
		rmdir --ignore-fail-on-non-empty "${ROOT}"/etc/dev.d/default "${ROOT}"/etc/dev.d 2>/dev/null
		if [[ -d ${ROOT}/etc/dev.d ]]
		then
			ewarn "You still have the directory /etc/dev.d on your system."
			ewarn "This is no longer used by udev and can be removed."
		fi
	fi

	# 64-device-mapper.rules now gets installed by sys-fs/device-mapper
	# remove it if user don't has sys-fs/device-mapper installed, 27 Jun 2007
	if [[ -f ${ROOT}/etc/udev/rules.d/64-device-mapper.rules ]] &&
		! has_version sys-fs/device-mapper
	then
			rm -f "${ROOT}"/etc/udev/rules.d/64-device-mapper.rules
			einfo "Removed unneeded file 64-device-mapper.rules"
	fi

	# requested in Bug #225033:
	elog
	elog "persistent-net assigns fixed names to network devices."
	elog "If you have problems with the persistent-net rules,"
	elog "just delete the rules file"
	elog "\trm ${ROOT}etc/udev/rules.d/70-persistent-net.rules"
	elog "then reboot."
	elog
	elog "This may however number your devices in a different way than they are now."

	ewarn
	ewarn "If you build an initramfs including udev, then please"
	ewarn "make sure that the /usr/bin/udevadm binary gets included,"
	ewarn "and your scripts changed to use it,as it replaces the"
	ewarn "old helper apps udevinfo, udevtrigger, ..."

	ewarn
	ewarn "mount options for directory /dev are no longer"
	ewarn "set in /etc/udev/udev.conf, but in /etc/fstab"
	ewarn "as for other directories."

	ewarn
	ewarn "If you use /dev/md/*, /dev/loop/* or /dev/rd/*,"
	ewarn "then please migrate over to using the device names"
	ewarn "/dev/md*, /dev/loop* and /dev/ram*."
	ewarn "The devfs-compat rules have been removed."
	ewarn "For reference see Bug #269359."

	ewarn
	ewarn "Rules for /dev/hd* devices have been removed"
	ewarn "Please migrate to libata."

	ewarn
	ewarn "action_modeswitch has been removed by upstream."
	ewarn "Please use sys-apps/usb_modeswitch."

	if ismounted /usr
	then
		ewarn
		ewarn "Your system has /usr on a separate partition. This means"
		ewarn "you will need to use an initramfs to pre-mount /usr before"
		ewarn "udev runs."
		ewarn "This must be set up before your next reboot, or you may"
		ewarn "experience failures which are very difficult to troubleshoot."
		ewarn "For a more detailed explanation, see the following URL:"
		ewarn "http://www.freedesktop.org/wiki/Software/systemd/separate-usr-is-broken"
	fi

	ewarn
	ewarn "The udev-acl functionality has been removed from udev."
	ewarn "This functionality will appear in a future version of consolekit."

	elog
	elog "For more information on udev on Gentoo, writing udev rules, and"
	elog "         fixing known issues visit:"
	elog "         http://www.gentoo.org/doc/en/udev-guide.xml"
}
