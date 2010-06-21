# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit qt4

DESCRIPTION="nzb is a graphical usenet nzb leecher with SSL support based on QT4"
HOMEPAGE="http://nzb.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=x11-libs/qt-4.3.3"
DEPEND="${RDEPEND}"

src_compile() {
	qmake || die "qmake failed"
	emake || die "emake failed"
}

src_install() {
	emake INSTALL_ROOT="${D}" install || die "make install failed"
	dodoc ChangeLog README
}
