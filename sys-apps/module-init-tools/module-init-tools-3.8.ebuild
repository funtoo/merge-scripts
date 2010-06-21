# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/module-init-tools/module-init-tools-3.8.ebuild,v 1.1 2009/05/24 19:52:53 vapier Exp $

inherit eutils

DESCRIPTION="tools for managing linux kernel modules"
HOMEPAGE="http://kerneltools.org/"
SRC_URI="mirror://kernel/linux/utils/kernel/module-init-tools/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE=""

DEPEND="sys-libs/zlib
	>=sys-apps/baselayout-2
	!virtual/modutils"
PROVIDE="virtual/modutils"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-3.2.2-handle-dupliate-aliases.patch #149426

	# dont bother building insmod.static
	sed -i \
		-e 's: insmod.static$(EXEEXT)::' \
		Makefile.in

	touch *.5 *.8 # dont regen manpages
}

src_compile() {
	econf \
		--prefix=/ \
		--enable-zlib \
		--enable-zlib-dynamic \
		|| die "econf failed"
	emake || die "emake module-init-tools failed"
}

src_test() {
	./tests/runtests || die
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS ChangeLog INSTALL NEWS README TODO

	dosym modprobe.conf.5 /usr/share/man/man5/modprobe.d.5

	into /
	newsbin "${FILESDIR}"/update-modules-3.5.sh update-modules || die
	doman "${FILESDIR}"/update-modules.8
}

pkg_postinst() {
	# cheat to keep users happy
	if grep -qs modules-update "${ROOT}"/etc/init.d/modules ; then
		sed -i 's:modules-update:update-modules:' "${ROOT}"/etc/init.d/modules
	fi
}
