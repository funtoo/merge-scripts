# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/texinfo/texinfo-4.11-r1.ebuild,v 1.12 2008/04/19 06:57:14 vapier Exp $

inherit flag-o-matic

DESCRIPTION="The GNU info program and utilities"
HOMEPAGE="http://www.gnu.org/software/texinfo/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="nls static"

RDEPEND="!=app-text/tetex-2* >=sys-libs/ncurses-5.2-r2 nls? ( virtual/libintl )"
DEPEND="${RDEPEND} nls? ( sys-devel/gettext )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	# pull in ctype.h for misc string function prototypes
	sed -i '1i#include <ctype.h>' system.h
	epatch "${FILESDIR}"/${P}-dir-entry.patch #198545
	epatch "${FILESDIR}"/${P}-test-tex.patch #195313
	epatch "${FILESDIR}"/${P}-test.patch #215359
	epatch "${FILESDIR}"/${P}-parallel-build.patch #214127

	# FreeBSD requires install-sh, but usptream don't have it marked
	# exec, #195076
	chmod +x build-aux/install-sh
}

src_compile() {
	use static && append-ldflags -static
	econf $(use_enable nls) || die
	emake || die "emake"
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"

	dodoc AUTHORS ChangeLog INTRODUCTION NEWS README TODO
	newdoc info/README README.info
	newdoc makeinfo/README README.makeinfo

	rm -f "${D}"/usr/lib/charset.alias #195148
}
