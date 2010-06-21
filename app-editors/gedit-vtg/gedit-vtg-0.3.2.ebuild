# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils autotools

MY_PN=$(echo ${PN#*-})

DESCRIPTION="Experimental plugin that extends gEdit."
HOMEPAGE="http://code.google.com/p/vtg/"
SRC_URI="http://${PN}.googlecode.com/files/${MY_PN}-${PV}.tar.bz2"

LICENSE="GPL-2+"
KEYWORDS="~x86 ~amd64"
SLOT="0"

IUSE=""

FEATURES="strict sandbox collision-protect"

DEPEND="
    >=app-editors/gedit-2.24.3
    >=dev-lang/vala-0.5.3
    >=dev-libs/gnome-build-2.23.90
    >=x11-libs/gtksourceview-gtksourcecompletion-0.5.1
    >=sys-libs/readline-5.2_p13"

RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_PN}-${PV}"

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
