# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-gfx/qosmic/qosmic-1.4.8.ebuild,v 1.1 2009/12/16 10:36:42 ssuominen Exp $

EAPI=2
inherit qt4

DESCRIPTION="A cosmic recursive flame fractal editor"
HOMEPAGE="http://code.google.com/p/qosmic/"
SRC_URI="http://qosmic.googlecode.com/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=">=dev-lang/lua-5.1.4
	>=media-gfx/flam3-2.7.18
	>=x11-libs/qt-gui-4.6:4"

src_configure() {
	eqmake4
}

src_install() {
	emake INSTALL_ROOT="${D}" install || die
	dodoc changes.txt README
}
