# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=1

inherit eutils qt4

DESCRIPTION="A cosmic recursive flame fractal editor written in Qt"
HOMEPAGE="http://qosmic.googlecode.com"
SRC_URI="${HOMEPAGE}/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="|| ( x11-libs/qt-gui:4 =x11-libs/qt-4.3* )
	>=media-gfx/flam3-2.7.16
	dev-libs/libxml2
	media-libs/libpng
	media-libs/jpeg
	dev-lang/lua"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${PN}

src_compile() {
	eqmake4
	emake || die "make failed"
}

src_install() {
	doicon icons/qosmicicon.xpm || die "doicon failed"
	dobin qosmic || die "dobin failed"
	dodoc README README-LUA || die "dodoc failed"
	make_desktop_entry qosmic "Qosmic" qosmicicon.xpm "KDE;Qt;Graphics"
}

