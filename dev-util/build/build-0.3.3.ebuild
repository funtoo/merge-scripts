# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="A massively-parallel software build system implemented on top of GNU make"
HOMEPAGE="http://kolpackov.net/projects/build/"
SRC_URI="ftp://kolpackov.net/pub/projects/${PN}/${PV%.?}/${P}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="examples"

DEPEND=""
RDEPEND="${DEPEND}"

src_install() {
	emake install_prefix="${D}/usr" install || die "emake install failed"

	dodoc NEWS README
	dohtml -A xhtml documentation/*.{css,xhtml}

	if use examples ; then
		# preserving symlinks in the examples
		cp -dpR examples "${D}/usr/share/doc/${PF}"
	fi
}
