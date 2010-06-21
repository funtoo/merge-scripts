# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/udev/udev-132.ebuild,v 1.1 2008/11/14 16:49:03 zzam Exp $

inherit eutils flag-o-matic multilib toolchain-funcs versionator autotools

DESCRIPTION="Linux dynamic and persistent device naming support (aka userspace devfs)"
HOMEPAGE="http://www.kernel.org/pub/linux/utils/kernel/hotplug/udev.html"
SRC_URI="mirror://kernel/linux/utils/kernel/hotplug/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc x86"
IUSE="selinux"

DEPEND="selinux? ( sys-libs/libselinux ) >=sys-apps/baselayout-2.1.6"
RDEPEND="!sys-apps/coldplug !<sys-fs/device-mapper-1.02.19-r1"
RDEPEND="${DEPEND} ${RDEPEND}"
PROVIDE="virtual/dev-manager"

sed_helper_dir() {
	sed -e "s#/lib/udev#${udev_helper_dir}#" -e "s#/lib64/udev#${udev_helper_dir}#" -i "$@"
}

pkg_setup() {
	udev_helper_dir="/$(get_libdir)/udev"
}

src_unpack() {
	unpack ${A}

	cd "${S}"

	#patches go here...
	epatch "${FILESDIR}/patches/${P}-fix-capi.diff"
	epatch "${FILESDIR}/patches/${P}-rules-update.diff"
	epatch "${FILESDIR}/patches/${P}-fix-dri-perms.diff"
	epatch "${FILESDIR}/patches/${PN}-fix-udevinfo-in-doc.diff"
	epatch "${FILESDIR}/patches/udev-135-security-backport-from-141.diff"

	sed_helper_dir \
		rules/rules.d/50-udev-default.rules \
		extras/rule_generator/write_*_rules \
		udev/udev-util.c \
		udev/udev-rules.c \
		udev/udevd.c \
		$(find -name "Makefile.*") || die "sed failed"

	# fix version of volume_id lib
	sed -e 's/-version-info/-version-number/' -i extras/volume_id/lib/Makefile.am

	eautoreconf
}

src_compile() {
	filter-flags -fprefetch-loop-arrays

	econf \
		--prefix=/usr \
		--sysconfdir=/etc \
		--exec-prefix= \
		--with-libdir-name=$(get_libdir) \
		--disable-logging \
		$(use_with selinux)

	emake || die "compiling udev failed"
}

src_install() {
	into /
	emake DESTDIR="${D}" install || die "make install failed"

	exeinto "${udev_helper_dir}"
	local x
	for x in net.sh move_tmp_persistent_rules.sh write_root_link_rule shell-compat.sh
	do
		doexe "${FILESDIR}/${PVR}/${x}" || die "${x} not installed properly"
	done

	keepdir "${udev_helper_dir}"/state
	keepdir "${udev_helper_dir}"/devices

	# Use Funtoo's "realdev" command to create initial set of device nodes in
	# /lib/udev/devices. This set of device nodes will be copied to /dev when
	# udev starts.

	$ROOT/sbin/realdev ${D}${udev_helper_dir}/devices || die

	# create symlinks for these utilities to /sbin
	# where multipath-tools expect them to be (Bug #168588)
	dosym "..${udev_helper_dir}/vol_id" /sbin/vol_id
	dosym "..${udev_helper_dir}/scsi_id" /sbin/scsi_id

	# Add gentoo stuff to udev.conf
	echo "# If you need to change mount-options, do it in /etc/fstab" >> "${D}"/etc/udev/udev.conf

	# let the dir exist at least
	keepdir /etc/udev/rules.d

	# Now installing rules
	cd "${S}"/rules
	insinto "${udev_helper_dir}"/rules.d/

	# Our rules files
	doins gentoo/??-*.rules
	doins packages/40-alsa.rules

	# Adding arch specific rules
	if [[ -f packages/40-${ARCH}.rules ]]
	then
		doins "packages/40-${ARCH}.rules"
	fi
	cd "${S}"

	# The udev-post init-script
	local x
	for x in udevd udev-save udev-mount udev-postmount
	do
		newinitd "${FILESDIR}"/${PVR}/${x}.initd ${x}
	done
	
	newconfd "${FILESDIR}/${PVR}/udev.confd" udev

	insinto /etc/modprobe.d
	newins "${FILESDIR}/${PVR}/blacklist" blacklist.conf
	newins "${FILESDIR}/${PVR}/pnp-aliases" pnp-aliases.conf

	# convert /lib/udev to real used dir
	sed_helper_dir "${D}"/etc/init.d/udev* "${D}"/etc/modprobe.d/*

	# documentation
	dodoc ChangeLog README TODO || die "failed installing docs"

	cd docs/writing_udev_rules || die
	mv index.html writing_udev_rules.html
	dohtml *.html

	cd "${S}" || die

	newdoc extras/volume_id/README README_volume_id

	echo "CONFIG_PROTECT_MASK=\"/etc/udev/rules.d\"" > 20udev
	doenvd 20udev
}

modfix() {
	local mod

	# We want to move any old modprobe.d conf files to the new file name so
	# config file protection works correctly.

	for mod in blacklist pnp-aliases 
	do
		if [ -e $ROOT/etc/modprobe.d/$mod ] 
		then
			mv $ROOT/etc/modprobe.d/$mod $ROOT/etc/modprobe.d/${mod}.conf || die "mv failed"
		fi
	done

}


pkg_preinst() {

	modfix

	if [[ -d ${ROOT}/lib/udev-state ]]
	then
		mv -f "${ROOT}"/lib/udev-state/* "${D}"/lib/udev/state/
		rm -r "${ROOT}"/lib/udev-state
	fi

	if [[ -f ${ROOT}/etc/udev/udev.config &&
	     ! -f ${ROOT}/etc/udev/udev.rules ]]
	then
		mv -f "${ROOT}"/etc/udev/udev.config "${ROOT}"/etc/udev/udev.rules
	fi

	# delete the old udev.hotplug symlink if it is present
	if [[ -h ${ROOT}/etc/hotplug.d/default/udev.hotplug ]]
	then
		rm -f "${ROOT}"/etc/hotplug.d/default/udev.hotplug
	fi

	# delete the old wait_for_sysfs.hotplug symlink if it is present
	if [[ -h ${ROOT}/etc/hotplug.d/default/05-wait_for_sysfs.hotplug ]]
	then
		rm -f "${ROOT}"/etc/hotplug.d/default/05-wait_for_sysfs.hotplug
	fi

	# delete the old wait_for_sysfs.hotplug symlink if it is present
	if [[ -h ${ROOT}/etc/hotplug.d/default/10-udev.hotplug ]]
	then
		rm -f "${ROOT}"/etc/hotplug.d/default/10-udev.hotplug
	fi

	has_version "=${CATEGORY}/${PN}-103-r3"
	previous_equal_to_103_r3=$?

	has_version "<${CATEGORY}/${PN}-104-r5"
	previous_less_than_104_r5=$?

	has_version "<${CATEGORY}/${PN}-106-r5"
	previous_less_than_106_r5=$?

	has_version "<${CATEGORY}/${PN}-113"
	previous_less_than_113=$?

	rm -f /etc/conf.d/udev #FORCE UPDATE
}

# See Bug #129204 for a discussion about restarting udevd
restart_udevd() {
	# need to merge to our system
	[[ ${ROOT} = / ]] || return

	# check if root of init-process is identical to ours (not in chroot)
	[[ -r /proc/1/root && /proc/1/root/ -ef /proc/self/root/ ]] || return

	# abort if there is no udevd running
	[[ -n $(pidof udevd) ]] || return

	# abort if /dev/.udev exists
	[[ -e /dev/.udev ]] || return

	elog
	elog "restarting udevd now."
	elog

	killall -15 udevd &>/dev/null
	sleep 1
	killall -9 udevd &>/dev/null

	/etc/init.d/udev zap > /dev/null 2>&1
	/etc/init.d/udevd zap > /dev/null 2>&1
	/etc/init.d/udevd start
}

# from the openrc-0.3.0.22081113 ebuild :)
add_init() {
	local runl=$1
	if [ ! -e ${ROOT}/etc/runlevels/${runl} ]
	then
		install -d -m0755 ${ROOT}/etc/runlevels/${runl}
	fi
	for initd in $*
	do
		# if the initscript is not going to be installed and  is not currently installed, return
		[[ -e ${D}/etc/init.d/${initd} || -e ${ROOT}/etc/init.d/${initd} ]] || continue
		[[ -e ${ROOT}/etc/runlevels/${runl}/${initd} ]] && continue
		elog "Auto-adding '${initd}' service to your ${runl} runlevel"
		ln -snf /etc/init.d/${initd} "${ROOT}"/etc/runlevels/${runl}/${initd}
	done
}

fix_old_persistent_net_rules() {
	local rules=${ROOT}/etc/udev/rules.d/70-persistent-net.rules
	[[ -f ${rules} ]] || return

	ebegin "Fixing persistent-net rules file"

	# Change ATTRS to ATTR matches, Bug #246927
	sed -i -e 's/ATTRS{/ATTR{/g' "${rules}"

	# Add KERNEL matches if missing, Bug #246849
	sed -ri \
		-e '/KERNEL/ ! { s/NAME="(eth|wlan|ath)([0-9]+)"/KERNEL=="\1*", NAME="\1\2"/}' \
		"${rules}"

	eend 0 ""
}

pkg_postinst() {

	# disable coldplug script
	rm -f $ROOT/etc/runlevels/*/coldplug

	# disable any old udev script
	rm -f $ROOT/etc/runlevels/*/udev

	rm -f $ROOT/etc/runlevels/*/udev-postmount

	add_init sysinit udev-mount
	add_init sysinit udevd
	add_init boot udev-postmount
	add_init shutdown udev-save

	# delete 40-scsi-hotplug.rules - all integrated in 50-udev.rules
	if [[ $previous_equal_to_103_r3 = 0 ]] &&
		[[ -e ${ROOT}/etc/udev/rules.d/40-scsi-hotplug.rules ]]
	then
		ewarn "Deleting stray 40-scsi-hotplug.rules"
		ewarn "installed by sys-fs/udev-103-r3"
		rm -f "${ROOT}"/etc/udev/rules.d/40-scsi-hotplug.rules
	fi

	# Removing some old file
	if [[ $previous_less_than_104_r5 = 0 ]]
	then
		rm -f "${ROOT}"/etc/dev.d/net/hotplug.dev
		rmdir --ignore-fail-on-non-empty "${ROOT}"/etc/dev.d/net 2>/dev/null
	fi

	if [[ $previous_less_than_106_r5 = 0 ]] &&
		[[ -e ${ROOT}/etc/udev/rules.d/95-net.rules ]]
	then
		rm -f "${ROOT}"/etc/udev/rules.d/95-net.rules
	fi

	# Try to remove /etc/dev.d as that is obsolete
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
	# remove it if user don't has sys-fs/device-mapper installed
	if [[ $previous_less_than_113 = 0 ]] &&
		[[ -f ${ROOT}/etc/udev/rules.d/64-device-mapper.rules ]] &&
		! has_version sys-fs/device-mapper
	then
			rm -f "${ROOT}"/etc/udev/rules.d/64-device-mapper.rules
			einfo "Removed unneeded file 64-device-mapper.rules"
	fi

	# requested in Bug #225033:
	elog
	elog "persistent-net does assigning fixed names to network devices."
	elog "If you prefer to disable persistent-net, this can be done via"
	elog "/etc/conf.d/udev."

	fix_old_persistent_net_rules
	restart_udevd

	ewarn
	ewarn "mount options for directory /dev are no longer"
	ewarn "set in /etc/udev/udev.conf, but in /etc/fstab"
	ewarn "as for other directories."

	elog
	elog "For more information on udev on Gentoo, writing udev rules, and"
	elog "         fixing known issues visit:"
	elog "         http://www.gentoo.org/doc/en/udev-guide.xml"
}
