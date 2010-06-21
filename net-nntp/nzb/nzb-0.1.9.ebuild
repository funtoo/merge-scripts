# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-nntp/nzb/nzb-0.1.9.ebuild,v 1.1 2009/11/08 22:00:04 ssuominen Exp $

EAPI=2
inherit eutils qt4

DESCRIPTION="A binary news grabber"
HOMEPAGE="http://www.nzb.fi/"
SRC_URI="mirror://sourceforge/nzb/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="x11-libs/qt-gui:4"

src_configure() {
	eqmake4
}

src_install() {
	emake INSTALL_ROOT="${D}" install || die
	dodoc ChangeLog README
	doicon images/nzb.png
	make_desktop_entry nzb nzb
}
