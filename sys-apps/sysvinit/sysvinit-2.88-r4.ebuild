# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/sysvinit/sysvinit-2.88-r3.ebuild,v 1.1 2011/08/29 21:21:44 vapier Exp $

inherit eutils toolchain-funcs flag-o-matic

DESCRIPTION="/sbin/init - parent of all processes"
HOMEPAGE="http://savannah.nongnu.org/projects/sysvinit"
SRC_URI="mirror://nongnu/${PN}/${P}dsf.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="selinux ibm static kernel_FreeBSD"

RDEPEND="selinux? ( >=sys-libs/libselinux-1.28 )"
DEPEND="${RDEPEND}
	virtual/os-headers"

S=${WORKDIR}/${P}dsf

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-2.86-kexec.patch #80220
	epatch "${FILESDIR}"/${PN}-2.86-shutdown-single.patch #158615
	epatch "${FILESDIR}"/${P}-makefile.patch #319197
	epatch "${FILESDIR}"/${P}-selinux.patch #326697
	sed -i '/^CPPFLAGS =$/d' src/Makefile || die

	# mountpoint has moved to util-linux
	sed -i \
		-e '/^BIN/s:mountpoint::' \
		-e '/^MAN1/s:mountpoint[.]1::' \
		src/Makefile || die

	# Mung inittab for specific architectures
	cd "${WORKDIR}"
	cp "${FILESDIR}"/inittab-2.87-r3 inittab || die "cp inittab"
	local insert=""
	use ppc && insert='#psc0:12345:respawn:/sbin/agetty 115200 ttyPSC0 linux'
	use arm && insert='#f0:12345:respawn:/sbin/agetty 9600 ttyFB0 vt100'
	use hppa && insert='b0:12345:respawn:/sbin/agetty 9600 ttyB0 vt100'
	use s390 && insert='s0:12345:respawn:/sbin/agetty 38400 console'
	if use ibm ; then
		insert="${insert}#hvc0:2345:respawn:/sbin/agetty -L 9600 hvc0"$'\n'
		insert="${insert}#hvsi:2345:respawn:/sbin/agetty -L 19200 hvsi0"
	fi
	(use arm || use mips || use sh || use sparc) && sed -i '/ttyS0/s:#::' inittab
	if use kernel_FreeBSD ; then
		sed -i \
			-e 's/linux/cons25/g' \
			-e 's/ttyS0/cuaa0/g' \
			-e 's/ttyS1/cuaa1/g' \
			inittab #121786
	fi
	[[ -n ${insert} ]] && echo "# Architecture specific features"$'\n'"${insert}" >> inittab
}

src_compile() {
	local myconf

	tc-export CC
	append-lfs-flags
	use static && append-ldflags -static
	use selinux && myconf=WITH_SELINUX=yes
	emake -C src ${myconf} || die
}

src_install() {
	emake -C src install ROOT="${D}" || die
	dodoc README doc/*

	insinto /etc
	doins "${WORKDIR}"/inittab || die "inittab"

	doinitd "${FILESDIR}"/{reboot,shutdown}.sh || die
}

pkg_postinst() {
	# Reload init to fix unmounting problems of / on next reboot.
	# This is really needed, as without the new version of init cause init
	# not to quit properly on reboot, and causes a fsck of / on next reboot.
	if [[ ${ROOT} == / ]] ; then
		# Do not return an error if this fails
		/sbin/telinit U &>/dev/null
	fi
}
