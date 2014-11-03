# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit autotools eutils linux-info multilib systemd toolchain-funcs udev

DESCRIPTION="User-land utilities for LVM2 (device-mapper) software."
HOMEPAGE="http://sources.redhat.com/lvm2/"
SRC_URI="ftp://sources.redhat.com/pub/lvm2/${PN/lvm/LVM}.${PV}.tgz
	ftp://sources.redhat.com/pub/lvm2/old/${PN/lvm/LVM}.${PV}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="readline +static +static-libs clvm cman +lvm1 lvm2create_initrd selinux udev thin"

DEPEND_COMMON="clvm? ( cman? ( =sys-cluster/cman-3* ) =sys-cluster/libdlm-3* )
	readline? ( sys-libs/readline )
	udev? ( >=virtual/libudev-208:=[static-libs?] )"
# /run is now required for locking during early boot. /var cannot be assumed to
# be available -- thus, pull in recent enough baselayout for /run.
# This version of LVM is incompatible with cryptsetup <1.1.2.
RDEPEND="${DEPEND_COMMON}
	>=sys-apps/baselayout-2.2
	>sys-apps/openrc-0.11
	!<sys-fs/cryptsetup-1.1.2
	!!sys-fs/clvm
	!!sys-fs/lvm-user
	>=sys-apps/util-linux-2.16
	lvm2create_initrd? ( sys-apps/makedev )
	thin? ( >=sys-block/thin-provisioning-tools-0.2.1 )"
DEPEND="${DEPEND_COMMON}
	virtual/pkgconfig
	>=sys-devel/binutils-2.20.1-r1
	static? (
		selinux? ( sys-libs/libselinux[static-libs] )
		udev? ( >=virtual/libudev-208:=[static-libs?] )
	)"

S=${WORKDIR}/${PN/lvm/LVM}.${PV}
MYDIR="$FILESDIR/2.02.103"

pkg_setup() {
	local CONFIG_CHECK="~SYSVIPC"

	if use udev; then
		local WARNING_SYSVIPC="CONFIG_SYSVIPC:\tis not set (required for udev sync)\n"
		if linux_config_exists; then
			local uevent_helper_path=$(linux_chkconfig_string UEVENT_HELPER_PATH)
			if [ -n "${uevent_helper_path}" ] && [ "${uevent_helper_path}" != '""' ]; then
				ewarn "It's recommended to set an empty value to the following kernel config option:"
				ewarn "CONFIG_UEVENT_HELPER_PATH=${uevent_helper_path}"
			fi
		fi
	fi

	check_extra_config

	# 1. Genkernel no longer copies /sbin/lvm blindly.
	if use static; then
		elog "Warning, we no longer overwrite /sbin/lvm and /sbin/dmsetup with"
		elog "their static versions. If you need the static binaries,"
		elog "you must append .static to the filename!"
	fi
}

src_prepare() {
	# Gentoo specific modification(s):
	epatch "${MYDIR}/${PN}-2.02.99-example.conf.in.patch"

	sed -i \
		-e "1iAR = $(tc-getAR)" \
		-e "s:CC ?= @CC@:CC = $(tc-getCC):" \
		make.tmpl.in || die #444082

	sed -i -e '/FLAG/s:-O2::' configure{,.in} || die #480212

	# For upstream -- review and forward:
	epatch "${MYDIR}/${PN}-2.02.63-always-make-static-libdm.patch"
	epatch "${MYDIR}/${PN}-2.02.56-lvm2create_initrd.patch"
	epatch "${MYDIR}/${PN}-2.02.67-createinitrd.patch" #301331
	epatch "${MYDIR}/${PN}-2.02.99-locale-muck.patch" #330373
	epatch "${MYDIR}/${PN}-2.02.70-asneeded.patch" # -Wl,--as-needed
	epatch "${MYDIR}/${PN}-2.02.92-dynamic-static-ldflags.patch" #332905
	epatch "${MYDIR}/${PN}-2.02.100-selinux_and_udev_static.patch" #370217, #439414

	eautoreconf
}

src_configure() {
	local myconf
	local buildmode

	myconf="${myconf} --enable-dmeventd"
	myconf="${myconf} --enable-cmdlib"
	myconf="${myconf} --enable-applib"
	myconf="${myconf} --enable-fsadm"
	myconf="${myconf} --enable-lvmetad"

	# Most of this package does weird stuff.
	# The build options are tristate, and --without is NOT supported
	# options: 'none', 'internal', 'shared'
	if use static; then
		buildmode="internal"
		# This only causes the .static versions to become available
		myconf="${myconf} --enable-static_link"
	else
		buildmode="shared"
	fi

	# dmeventd requires mirrors to be internal, and snapshot available
	# so we cannot disable them
	myconf="${myconf} --with-mirrors=internal"
	myconf="${myconf} --with-snapshots=internal"
	use thin \
		&& myconf="${myconf} --with-thin=internal" \
		|| myconf="${myconf} --with-thin=none"

	if use lvm1; then
		myconf="${myconf} --with-lvm1=${buildmode}"
	else
		myconf="${myconf} --with-lvm1=none"
	fi

	# disable O_DIRECT support on hppa, breaks pv detection (#99532)
	use hppa && myconf="${myconf} --disable-o_direct"

	if use clvm; then
		myconf="${myconf} --with-cluster=${buildmode}"
		# 4-state! Make sure we get it right, per bug 210879
		# Valid options are: none, cman, gulm, all
		#
		# 2009/02:
		# gulm is removed now, now dual-state:
		# cman, none
		# all still exists, but is not needed
		#
		# 2009/07:
		# TODO: add corosync and re-enable ALL
		local clvmd=""
		use cman && clvmd="cman"
		#clvmd="${clvmd/cmangulm/all}"
		[ -z "${clvmd}" ] && clvmd="none"
		myconf="${myconf} --with-clvmd=${clvmd}"
		myconf="${myconf} --with-pool=${buildmode}"
	else
		myconf="${myconf} --with-clvmd=none --with-cluster=none"
	fi

	econf \
		$(use_enable readline) \
		$(use_enable selinux) \
		--enable-pkgconfig \
		--with-confdir="${EPREFIX}"/etc \
		--exec-prefix="${EPREFIX}" \
		--sbindir="${EPREFIX}/sbin" \
		--with-staticdir="${EPREFIX}"/sbin \
		--libdir="${EPREFIX}/$(get_libdir)" \
		--with-usrlibdir="${EPREFIX}/usr/$(get_libdir)" \
		--with-default-dm-run-dir=/run \
		--with-default-run-dir=/run/lvm \
		--with-default-locking-dir=/run/lock/lvm \
		--with-default-pid-dir=/run \
		$(use_enable udev udev_rules) \
		$(use_enable udev udev_sync) \
		$(use_with udev udevdir "$(get_udevdir)"/rules.d) \
		"$(systemd_with_unitdir)" \
		${myconf} \
		CLDFLAGS="${LDFLAGS}"
}

src_compile() {
	pushd include >/dev/null
	emake
	popd >/dev/null

	emake
	emake CC="$(tc-getCC)" -C scripts lvm2_activation_generator_systemd_red_hat
}

src_install() {
	local inst
	for inst in install install_systemd_units install_systemd_generators install_tmpfiles_configuration; do
		emake DESTDIR="${D}" ${inst}
	done

	newinitd "${MYDIR}"/lvm.rc-2.02.95-r2 lvm
	newconfd "${MYDIR}"/lvm.confd-2.02.28-r2 lvm

	newinitd "${MYDIR}"/lvm-monitoring.initd-2.02.67-r2 lvm-monitoring

	newinitd "${MYDIR}"/device-mapper.rc-2.02.95-r2 device-mapper
	newconfd "${MYDIR}"/device-mapper.conf-1.02.22-r3 device-mapper

	newinitd "${MYDIR}"/dmeventd.initd-2.02.67-r1 dmeventd

	if use clvm; then
		newinitd "${MYDIR}"/clvmd.rc-2.02.39 clvmd
		newconfd "${MYDIR}"/clvmd.confd-2.02.39 clvmd
	fi

	if use static-libs; then
		dolib.a libdm/ioctl/libdevmapper.a
		dolib.a libdaemon/client/libdaemonclient.a #462908
		#gen_usr_ldscript libdevmapper.so
		dolib.a daemons/dmeventd/libdevmapper-event.a
		#gen_usr_ldscript libdevmapper-event.so
	else
		rm -f "${ED}"usr/$(get_libdir)/{libdevmapper-event,liblvm2cmd,liblvm2app,libdevmapper}.a
	fi

	if use lvm2create_initrd; then
		dosbin scripts/lvm2create_initrd/lvm2create_initrd
		doman scripts/lvm2create_initrd/lvm2create_initrd.8
		newdoc scripts/lvm2create_initrd/README README.lvm2create_initrd
	fi

	insinto /etc
	doins "${MYDIR}"/dmtab

	dodoc README VERSION* WHATS_NEW WHATS_NEW_DM doc/*.{c,txt} conf/*.conf
}

add_init() {
	local runl=$1
	shift
		if [ ! -e ${ROOT}etc/runlevels/${runl} ]
		then
			install -d -m0755 ${ROOT}etc/runlevels/${runl}
		fi
		for initd in $*
		do
			einfo "Auto-adding '${initd}' service to your ${runl} runlevel"
			[[ -e ${ROOT}etc/runlevels/${runl}/${initd} ]] && continue
			[[ ! -e ${ROOT}etc/init.d/${initd} ]] && die "initscript $initd not found; aborting"
			ln -snf /etc/init.d/${initd} "${ROOT}etc/runlevels/${runl}/${initd}"
		done
}
pkg_postinst() {
	add_init boot device-mapper lvm
}

src_test() {
	einfo "Tests are disabled because of device-node mucking, if you want to"
	einfo "run tests, compile the package and see ${S}/tests"
}
