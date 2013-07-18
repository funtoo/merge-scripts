# Distributed under the terms of the GNU General Public License v2

EAPI=5

# accept4() patch is only in non-live version
if [[ ${PV} = 9999* ]]; then
	KV_min=2.6.39
else
	KV_min=2.6.32
fi

inherit autotools eutils linux-info multilib toolchain-funcs versionator

if [[ ${PV} = 9999* ]]; then
	EGIT_REPO_URI="git://anongit.freedesktop.org/systemd/systemd"
	inherit git-2
else
	patchset=2
	SRC_URI="http://www.freedesktop.org/software/systemd/systemd-${PV}.tar.xz"
	if [[ -n "${patchset}" ]]; then
				SRC_URI="${SRC_URI}
					http://dev.gentoo.org/~ssuominen/${P}-patches-${patchset}.tar.xz
					http://dev.gentoo.org/~williamh/dist/${P}-patches-${patchset}.tar.xz"
			fi
	KEYWORDS="*"
fi

DESCRIPTION="Linux dynamic and persistent device naming support (aka userspace devfs)"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd"

LICENSE="LGPL-2.1 MIT GPL-2"
SLOT="0"
IUSE="acl doc firmware-loader +gudev +hwdb introspection keymap +kmod selinux static-libs"

RESTRICT="test"

COMMON_DEPEND=">=sys-apps/util-linux-2.20
	acl? ( sys-apps/acl )
	gudev? ( >=dev-libs/glib-2 )
	introspection? ( >=dev-libs/gobject-introspection-1.31.1 )
	kmod? ( >=sys-apps/kmod-13 )
	selinux? ( >=sys-libs/libselinux-2.1.9 )
	!<sys-libs/glibc-2.11
	!sys-apps/systemd"

DEPEND="${COMMON_DEPEND}
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt
	>=sys-devel/make-3.82-r4
	virtual/os-headers
	virtual/pkgconfig
	!<sys-kernel/linux-headers-${KV_min}
	doc? ( >=dev-util/gtk-doc-1.18 )
	keymap? ( dev-util/gperf )"

if [[ ${PV} = 9999* ]]; then
	DEPEND="${DEPEND}
		dev-util/gperf
		>=dev-util/intltool-0.50"
fi

RDEPEND="${COMMON_DEPEND}
	!sys-apps/coldplug
	!sys-fs/device-mapper
	!<sys-kernel/dracut-017-r1
	!<sys-kernel/genkernel-3.4.25
	!<sec-policy/selinux-base-2.20120725-r10"

PDEPEND=">=virtual/udev-197
	hwdb? ( sys-apps/hwids )"

S=${WORKDIR}/systemd-${PV}

#QA_MULTILIB_PATHS="lib/systemd/systemd-udevd"

udev_check_KV() {
	if kernel_is lt ${KV_min//./ }; then
		return 1
	fi
	return 0
}

check_default_rules() {
	# Make sure there are no sudden changes to upstream rules file
	# (more for my own needs than anything else ...)
	local udev_rules_md5=7d3733faee4203fd7c75c3f3c0d55741
	MD5=$(md5sum < "${S}"/rules/50-udev-default.rules)
	MD5=${MD5/  -/}
	if [[ ${MD5} != ${udev_rules_md5} ]]; then
		eerror "50-udev-default.rules has been updated, please validate!"
		eerror "md5sum: ${MD5}"
		die "50-udev-default.rules has been updated, please validate!"
	fi
}

pkg_setup() {
	CONFIG_CHECK="~BLK_DEV_BSG ~DEVTMPFS ~!IDE ~INOTIFY_USER ~!SYSFS_DEPRECATED ~!SYSFS_DEPRECATED_V2 ~SIGNALFD ~EPOLL"

	linux-info_pkg_setup

	if ! udev_check_KV; then
		eerror "Your kernel version (${KV_FULL}) is too old to run ${P}"
		eerror "It must be at least ${KV_min}!"
	fi

	KV_FULL_SRC=${KV_FULL}
	get_running_version
	if ! udev_check_KV; then
		eerror
		eerror "Your running kernel version (${KV_FULL}) is too old"
		eerror "for this version of udev."
		eerror "You must upgrade your kernel or downgrade udev."
	fi
}

src_prepare() {
	if ! [[ ${PV} = 9999* ]]; then
		# secure_getenv() disable for non-glibc systems wrt bug #443030
		if ! [[ $(grep -r secure_getenv * | wc -l) -eq 19 ]]; then
			eerror "The line count for secure_getenv() failed, see bug #443030"
			die
		fi

		# gperf disable if keymaps are not requested wrt bug #452760
		if ! [[ $(grep -i gperf Makefile.am | wc -l) -eq 27 ]]; then
			eerror "The line count for gperf references failed, see bug 452760"
			die
		fi
	fi

	# backport some patches
	if [[ -n "${patchset}" ]]; then
		EPATCH_SUFFIX=patch EPATCH_FORCE=yes epatch
	fi

	# These are missing from upstream 50-udev-default.rules
	cat <<-EOF > "${T}"/40-gentoo.rules
	# Gentoo specific usb group
	SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", GROUP="usb"
	# Keep this for Linux 2.6.32 kernels with accept4() support like .60 wrt #457868
	SUBSYSTEM=="mem", KERNEL=="null|zero|full|random|urandom", MODE="0666"
	EOF

	# Remove requirements for gettext and intltool wrt bug #443028
	if ! has_version dev-util/intltool && ! [[ ${PV} = 9999* ]]; then
		sed -i \
			-e '/INTLTOOL_APPLIED_VERSION=/s:=.*:=0.40.0:' \
			-e '/XML::Parser perl module is required for intltool/s|^|:|' \
			configure || die
		eval export INTLTOOL_{EXTRACT,MERGE,UPDATE}=/bin/true
		eval export {MSG{FMT,MERGE},XGETTEXT}=/bin/true
	fi

	# apply user patches
	epatch_user

	# compile with older versions of gcc #451110
	version_is_at_least 4.6 $(gcc-version) || \
		sed -i 's:static_assert:alsdjflkasjdfa:' src/shared/macro.h

	# change rules back to group uucp instead of dialout for now wrt #454556
	sed -e 's/GROUP="dialout"/GROUP="uucp"/' \
		-i rules/*.rules \
	|| die "failed to change group dialout to uucp"

	if [[ ! -e configure ]]; then
		if use doc; then
			gtkdocize --docdir docs || die "gtkdocize failed"
		else
			echo 'EXTRA_DIST =' > docs/gtk-doc.make
		fi
		eautoreconf
	else
		check_default_rules
		elibtoolize
	fi

	if ! use elibc_glibc; then #443030
		echo '#define secure_getenv(x) NULL' >> config.h.in
		sed -i -e '/error.*secure_getenv/s:.*:#define secure_getenv(x) NULL:' src/shared/missing.h || die
	fi

	# link udevd(8) and systemd-udevd(8) manpages to systemd-udevd.service(8) manpage
	echo '.so systemd-udevd.service.8' > "${T}"/udevd.8
	echo '.so systemd-udevd.service.8' > "${T}"/systemd-udevd.8
}

src_configure() {
	tc-export CC #463846
	use keymap || export ac_cv_prog_ac_ct_GPERF=true #452760

	local econf_args

	econf_args=(
		ac_cv_search_cap_init=
		ac_cv_header_sys_capability_h=yes
		DBUS_CFLAGS=' '
		DBUS_LIBS=' '
		--bindir=/bin
		--docdir=/usr/share/doc/${PF}
		--libdir=/usr/$(get_libdir)
		--with-html-dir=/usr/share/doc/${PF}/html
		--with-rootprefix=
		--with-rootlibdir=/$(get_libdir)
		--with-bashcompletiondir=/usr/share/bash-completion
		--without-python
		--disable-audit
		--disable-coredump
		--disable-hostnamed
		--disable-ima
		--disable-libcryptsetup
		--disable-localed
		--disable-logind
		--disable-myhostname
		--disable-nls
		--disable-pam
		--disable-quotacheck
		--disable-readahead
		--enable-split-usr
		--disable-tcpwrap
		--disable-timedated
		--disable-xz
		--disable-polkit
		$(use_enable acl)
		$(use_enable doc gtk-doc)
		$(use_enable gudev)
		$(use_enable keymap)
		$(use_enable kmod)
		$(use_enable selinux)
		$(use_enable static-libs static)
	)
	if use introspection; then
		econf_args+=(
			--enable-introspection=$(usex introspection)
		)
	fi
	if use firmware-loader; then
		econf_args+=(
			--with-firmware-path="/lib/firmware/updates:/lib/firmware"
		)
	fi
	econf "${econf_args[@]}"
}

src_compile() {
	echo 'BUILT_SOURCES: $(BUILT_SOURCES)' > "${T}"/Makefile.extra
	emake -f Makefile -f "${T}"/Makefile.extra BUILT_SOURCES
	local targets=(
		libudev.la
		systemd-udevd
		udevadm
		ata_id
		cdrom_id
		collect
		scsi_id
		v4l_id
		accelerometer
		mtd_probe
		man/udev.7
		man/udevadm.8
		man/systemd-udevd.service.8
	)
	use keymap && targets+=( keymap )
	use gudev && targets+=( libgudev-1.0.la )

	emake "${targets[@]}"
	if use doc; then
		emake -C docs/libudev
		use gudev && emake -C docs/gudev
	fi
}

src_install() {
	local lib_LTLIBRARIES="libudev.la" \
		pkgconfiglib_DATA="src/libudev/libudev.pc"

	local targets=(
		install-libLTLIBRARIES
		install-includeHEADERS
		install-libgudev_includeHEADERS
		install-binPROGRAMS
		install-rootlibexecPROGRAMS
		install-udevlibexecPROGRAMS
		install-dist_udevconfDATA
		install-dist_udevhomeSCRIPTS
		install-dist_udevkeymapDATA
		install-dist_udevkeymapforcerelDATA
		install-dist_udevrulesDATA
		install-girDATA
		install-man7
		install-man8
		install-pkgconfiglibDATA
		install-sharepkgconfigDATA
		install-typelibsDATA
		install-dist_docDATA
		libudev-install-hook
		install-directories-hook
		install-dist_bashcompletionDATA
	)

	if use gudev; then
		lib_LTLIBRARIES+=" libgudev-1.0.la"
		pkgconfiglib_DATA+=" src/gudev/gudev-1.0.pc"
	fi

	# add final values of variables:
	targets+=(
		rootlibexec_PROGRAMS=systemd-udevd
		bin_PROGRAMS=udevadm
		lib_LTLIBRARIES="${lib_LTLIBRARIES}"
		MANPAGES="man/udev.7 man/udevadm.8 \
				man/systemd-udevd.service.8"
		MANPAGES_ALIAS=""
		pkgconfiglib_DATA="${pkgconfiglib_DATA}"
		INSTALL_DIRS='$(sysconfdir)/udev/rules.d \
				$(sysconfdir)/udev/hwdb.d'
		dist_bashcompletion_DATA="shell-completion/bash/udevadm"
	)
	emake -j1 DESTDIR="${D}" "${targets[@]}"
	if use doc; then
		emake -C docs/libudev DESTDIR="${D}" install
		use gudev && emake -C docs/gudev DESTDIR="${D}" install
	fi
	dodoc TODO

	prune_libtool_files --all
	rm -f \
		"${D}"/lib/udev/rules.d/99-systemd.rules \
		"${D}"/usr/share/doc/${PF}/LICENSE.*

	# see src_prepare() for content of these files
	insinto /lib/udev/rules.d
	doins "${T}"/40-gentoo.rules
	doman "${T}"/udevd.8
	doman "${T}"/systemd-udevd.8
	newinitd "${FILESDIR}/udev.initd" udev
	newconfd "${FILESDIR}/udev.confd" udev

	# install udevadm compatibility symlink
	dosym {../bin,sbin}/udevadm

	# install udevd to /sbin and remove empty and redudant directory
	# /lib/systemd because systemd is installed to /usr wrt #462750
	mv "${D}"/{lib/systemd/systemd-,sbin/}udevd || die
	rm -r "${D}"/lib/systemd
	dosym /dev/null /etc/udev/rules.d/80-net-name-slot.rules
}

pkg_preinst() {
	local htmldir
	for htmldir in gudev libudev; do
		if [[ -d ${ROOT}usr/share/gtk-doc/html/${htmldir} ]]; then
			rm -rf "${ROOT}"usr/share/gtk-doc/html/${htmldir}
		fi
		if [[ -d ${D}/usr/share/doc/${PF}/html/${htmldir} ]]; then
			dosym ../../doc/${PF}/html/${htmldir} \
				/usr/share/gtk-doc/html/${htmldir}
		fi
	done
	preserve_old_lib /{,usr/}$(get_libdir)/libudev$(get_libname 0)
}

pkg_postinst() {
	mkdir -p "${ROOT}"run

	# "losetup -f" is confused if there is an empty /dev/loop/, Bug #338766
	# So try to remove it here (will only work if empty).
	rmdir "${ROOT}"dev/loop 2>/dev/null
	if [[ -d ${ROOT}dev/loop ]]; then
		ewarn "Please make sure your remove /dev/loop,"
		ewarn "else losetup may be confused when looking for unused devices."
	fi

	# people want reminders, I'll give them reminders.  Odds are they will
	# just ignore them anyway...

	# 64-device-mapper.rules is related to sys-fs/device-mapper which we block
	# in favor of sys-fs/lvm2
	old_dm_rules=${ROOT}etc/udev/rules.d/64-device-mapper.rules
	if [[ -f ${old_dm_rules} ]]; then
		rm -f "${old_dm_rules}"
		einfo "Removed unneeded file ${old_dm_rules}"
	fi

	local fstab="${ROOT}"etc/fstab dev path fstype rest
	while read -r dev path fstype rest; do
		if [[ ${path} == /dev && ${fstype} != devtmpfs ]]; then
			ewarn "You need to edit your /dev line in ${fstab} to have devtmpfs"
			ewarn "filesystem. Otherwise udev won't be able to boot."
			ewarn "See, http://bugs.gentoo.org/453186"
		fi
	done < "${fstab}"

	if [[ -d ${ROOT}usr/lib/udev ]]; then
		ewarn
		ewarn "Please re-emerge all packages on your system which install"
		ewarn "rules and helpers in /usr/lib/udev. They should now be in"
		ewarn "/lib/udev."
		ewarn
		ewarn "One way to do this is to run the following command:"
		ewarn "emerge -av1 \$(qfile -q -S -C /usr/lib/udev)"
		ewarn "Note that qfile can be found in app-portage/portage-utils"
	fi


	local old_cd_rules="${ROOT}"etc/udev/rules.d/70-persistent-cd.rules
	for old_rules in "${old_cd_rules}"; do
		if [[ -f ${old_rules} ]]; then
			ewarn
			ewarn "File ${old_rules} is from old udev installation but if you still use it,"
			ewarn "rename it to something else starting with 70- to silence this deprecation"
			ewarn "warning."
		fi
	done

	if has_version sys-apps/biosdevname; then
		ewarn
		ewarn "You have sys-apps/biosdevname installed which has been deprecated"
		ewarn "in favor of the predictable network interface names."
	fi

	ewarn
	ewarn "You need to restart udev as soon as possible to make the upgrade go"
	ewarn "into effect."
	ewarn "The method you use to do this depends on your init system."

	preserve_old_lib_notify /{,usr/}$(get_libdir)/libudev$(get_libname 0)

	elog
	elog "For more information on udev on Gentoo, upgrading, writing udev rules, and"
	elog "         fixing known issues visit:"
	elog "         http://wiki.gentoo.org/wiki/Udev/upgrade"
	elog "         http://www.gentoo.org/doc/en/udev-guide.xml"

	# Update hwdb database in case the format is changed by udev version.
	if use hwdbv; then
		udevadm hwdb --update --root="${ROOT%/}"
	fi
}
