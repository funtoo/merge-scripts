# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libedit/libedit-20050930.ebuild,v 1.6 2006/11/17 03:27:21 vapier Exp $

inherit eutils

DESCRIPTION="BSD replacement for libreadline"
HOMEPAGE="http://cvsweb.netbsd.org/bsdweb.cgi/src/lib/libedit/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh x86"
IUSE=""
RESTRICT="test"

DEPEND="sys-libs/ncurses"

S=${WORKDIR}/netbsd-cvs

src_unpack() {
	unpack ${A}
	cd "${S}"
	mv "${WORKDIR}"/glibc-*/*.c .
	epatch "${FILESDIR}"/${PN}-20050531-debian-to-gentoo.patch
}

src_compile() {
	emake -j1 .depend || die "depend"
	emake || die "make"
}

src_install() {
	dolib.so libedit.so || die "dolib.so"
	dolib.a libedit.a || die "dolib.a"
	insinto /usr/include
	doins histedit.h || die "doins *.h"
	doman *.[35]
}
