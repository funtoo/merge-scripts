# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/lvm2/lvm2-2.02.51-r3.ebuild,v 1.4 2009/12/11 15:44:06 armin76 Exp $

EAPI=2
inherit eutils multilib toolchain-funcs autotools

DESCRIPTION="User-land utilities for LVM2 (device-mapper) software."
HOMEPAGE="http://sources.redhat.com/lvm2/"
SRC_URI="ftp://sources.redhat.com/pub/lvm2/${PN/lvm/LVM}.${PV}.tgz
		 ftp://sources.redhat.com/pub/lvm2/old/${PN/lvm/LVM}.${PV}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"

IUSE="readline +static clvm cman +lvm1 selinux"

DEPEND="!!sys-fs/device-mapper
	clvm? ( =sys-cluster/dlm-2*
		cman? ( =sys-cluster/cman-2* ) )"

RDEPEND="${DEPEND}
	!<sys-apps/openrc-0.4
	!!sys-fs/lvm-user
	!!sys-fs/clvm
	>=sys-apps/util-linux-2.16"

S="${WORKDIR}/${PN/lvm/LVM}.${PV}"

pkg_setup() {
	# 1. Genkernel no longer copies /sbin/lvm blindly.
	# 2. There are no longer any linking deps in /usr.
	if use static; then
		elog "Warning, we no longer overwrite /sbin/lvm and /sbin/dmsetup with"
		elog "their static versions. If you need the static binaries,"
		elog "you must append .static the filename!"
	fi
}

src_unpack() {
	unpack ${A}
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.02.45-dmeventd.patch
	epatch "${FILESDIR}"/lvm.conf-2.02.51.patch
	epatch "${FILESDIR}"/${PN}-2.02.51-device-mapper-export-format.patch
	epatch "${FILESDIR}"/${PN}-2.02.51-as-needed.patch
	epatch "${FILESDIR}"/${PN}-2.02.48-fix-pkgconfig.patch
	epatch "${FILESDIR}"/${PN}-2.02.51-fix-pvcreate.patch
	epatch "${FILESDIR}"/${PN}-2.02.51-dmsetup-selinux-linking-fix-r3.patch
	eautoreconf
}

src_configure() {
	local myconf
	local buildmode

	myconf="${myconf} --enable-dmeventd"
	myconf="${myconf} --enable-cmdlib"
	myconf="${myconf} --enable-applib"
	myconf="${myconf} --enable-fsadm"

	# Most of this package does weird stuff.
	# The build options are tristate, and --without is NOT supported
	# options: 'none', 'internal', 'shared'
	if use static ; then
		einfo "Building static LVM, for usage inside genkernel"
		buildmode="internal"
		# This only causes the .static versions to become available
		# For recent systems, there are no linkages against anything in /usr anyway.
		# We explicitly provide the .static versions so that they can be included in
		# initramfs environments.
		myconf="${myconf} --enable-static_link"
	else
		ewarn "Building shared LVM, it will not work inside genkernel!"
		buildmode="shared"
	fi

	# dmeventd requires mirrors to be internal, and snapshot available
	# so we cannot disable them
	myconf="${myconf} --with-mirrors=internal"
	myconf="${myconf} --with-snapshots=internal"

	if use lvm1 ; then
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

	myconf="${myconf} --sbindir=/sbin --with-staticdir=/sbin"
	econf $(use_enable readline) \
		$(use_enable selinux) \
		--enable-pkgconfig \
		--libdir=/usr/$(get_libdir) \
		${myconf} \
		CLDFLAGS="${LDFLAGS}" || die
}

src_compile() {
	einfo "Doing symlinks"
	pushd include
	emake || die "Failed to prepare symlinks"
	popd

	einfo "Starting main build"
	emake || die "compile fail"
}

src_install() {
	emake DESTDIR="${D}" install

	dodir /$(get_libdir)
	# Put these in root so we can reach before /usr is up
	for i in \
		libdevmapper-event{,-lvm2{mirror,snapshot}} \
		libdevmapper \
		liblvm2{format1,snapshot,cmd} \
		; do
		b="${D}"/usr/$(get_libdir)/${i}
		if [ -f "${b}".so ]; then
			mv -f "${b}".so* "${D}"/$(get_libdir) || die
			gen_usr_ldscript ${i}.so || die
		fi
	done

	dodoc README VERSION WHATS_NEW doc/*.{conf,c,txt}
	insinto /$(get_libdir)/rcscripts/addons
	newins "${FILESDIR}"/lvm2-start.sh-2.02.49-r3 lvm-start.sh || die
	newins "${FILESDIR}"/lvm2-stop.sh-2.02.49-r3 lvm-stop.sh || die
	newinitd "${FILESDIR}"/lvm.rc-2.02.51-r2 lvm || die
	newconfd "${FILESDIR}"/lvm.confd-2.02.28-r2 lvm || die
	if use clvm; then
		newinitd "${FILESDIR}"/clvmd.rc-2.02.39 clvmd || die
		newconfd "${FILESDIR}"/clvmd.confd-2.02.39 clvmd || die
	fi

	# move shared libs to /lib(64)
	if use static; then
		dolib.a libdm/ioctl/libdevmapper.a || die "dolib.a libdevmapper.a"
	fi
	#gen_usr_ldscript libdevmapper.so

	insinto /etc
	doins "${FILESDIR}"/dmtab
	insinto /$(get_libdir)/rcscripts/addons
	doins "${FILESDIR}"/dm-start.sh

	# Device mapper stuff
	newinitd "${FILESDIR}"/device-mapper.rc-1.02.51-r2 device-mapper || die
	newconfd "${FILESDIR}"/device-mapper.conf-1.02.22-r3 device-mapper || die

	newinitd "${FILESDIR}"/1.02.22-dmeventd.initd dmeventd || die
	if use static; then
		dolib.a daemons/dmeventd/libdevmapper-event.a \
		|| die "dolib.a libdevmapper-event.a"
	fi
	#gen_usr_ldscript libdevmapper-event.so

	insinto /etc/udev/rules.d/
	newins "${FILESDIR}"/64-device-mapper.rules-1.02.49-r2 64-device-mapper.rules || die

	# do not rely on /lib -> /libXX link
	sed -e "s-/lib/rcscripts/-/$(get_libdir)/rcscripts/-" -i "${D}"/etc/init.d/*

	elog "USE flag nocman is deprecated and replaced"
	elog "with the cman USE flag."
	elog ""
	elog "USE flags clvm and cman are masked"
	elog "by default and need to be unmasked to use them"
	elog ""
	elog "If you are using genkernel and root-on-LVM, rebuild the initramfs."
}

pkg_postinst() {
	elog "lvm volumes are no longer automatically created for"
	elog "baselayout-2 users. If you are using baselayout-2, be sure to"
	elog "run: # rc-update add lvm boot"
	elog "Do NOT add it if you are using baselayout-1 still."
}

src_test() {
	einfo "Testcases disabled because of device-node mucking"
	einfo "If you want them, compile the package and see ${S}/tests"
}
