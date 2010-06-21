# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="The world's most popular open source database."
HOMEPAGE="http://www.valaide.org/"
SRC_URI="http://${PN}.googlecode.com/files/${PN}-${PV}.tar.gz"

LICENSE="GPL-3"
KEYWORDS="~x86 ~amd64"
SLOT="0"

IUSE="-doc -test"

FEATURES="strict sandbox collision-protect"

DEPEND="
    >=x11-libs/gtk+-2.10
    >=x11-libs/gtksourceview-2.0
    dev-lang/vala"

RDEPEND="${DEPEND}"

src_compile() {
    ./waf configure --prefix=/usr/ || die "configure failed"

    ./waf || die "make failed"
}

src_install() {
    DESTDIR=${D} ./waf install
}
