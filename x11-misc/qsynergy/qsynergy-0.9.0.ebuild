# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: qsynergy-0.9.0.ebuild, v1.0 j0inty $

inherit eutils qt4

DESCRIPTION="QSynergy is a comprehensive and easy to use graphical front end for Synergy."
HOMEPAGE="http://www.volker-lanz.de/en/software/qsynergy/"
SRC_URI="http://www.volker-lanz.de/static/${PN}/${P}.tar.gz"

ICON="dist/${PN}.xpm"

RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64 ~ppc ~ppc64"
IUSE=""

DEPEND=">=x11-libs/qt-4.3"
RDEPEND="${DEPEND}
		x11-misc/synergy"

src_compile() {
	eqmake4 || die "eqmake4 failed"
	emake || die "emake failed"
}

src_install() {
	dobin ${PN}
	dodoc README
	doicon ${ICON}
	make_desktop_entry ${PN} QSynergy ${PN}
}
