# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils autotools mono multilib

DESCRIPTION="Experimental extension for MonoDevelop"
HOMEPAGE="http://www.monodevelop.com/"
SRC_URI="http://files.mirthil.org/sources/${P}.tar.bz2"

LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64"
SLOT="0"

IUSE="debug"

FEATURES="strict sandbox collision-protect"

DEPEND="
    =dev-util/monodevelop-1.9.2"

RDEPEND="${DEPEND}"

src_compile() {
    MD_PYTHON_CONFIG=""

    if use debug ; then
        MD_PYTHON_CONFIG="--config=DEBUG"
    else
        MD_PYTHON_CONFIG="--config=RELEASE"
    fi

    ./configure --prefix=/usr ${MD_PYTHON_CONFIG} || die "configure failed"

    emake -j1 || die "make failed"
}

src_install() {
    emake -j1 DESTDIR="${D}" install || die "install failed"
}
