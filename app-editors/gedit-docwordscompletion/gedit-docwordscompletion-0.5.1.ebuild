# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils autotools

DESCRIPTION="Experimental plugin that extends gEdit."
HOMEPAGE="http://gtksourcecomple.sourceforge.net/"
SRC_URI="http://internap.dl.sourceforge.net/sourceforge/gtksourcecomple/${PN}-${PV}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64"
SLOT="0"

IUSE=""

FEATURES="strict sandbox collision-protect"

DEPEND="
    >=x11-libs/gtksourceview-gtksourcecompletion-0.5.2"

RDEPEND="${DEPEND}"

src_unpack() {
    unpack ${A}
    cd "${S}"

    eautoreconf || die "eautoreconf failed"
}

src_compile() {
    cd "${S}"
    econf || die "configure failed"

    emake || die "make failed"
}

src_test() {
    make check || die "make check failed"
}

src_install() {
    cd "${S}"

    emake DESTDIR="${D}" install || die "install failed"
}
