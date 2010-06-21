# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/quimup/quimup-1.1.0.ebuild,v 1.1 2010/06/03 20:04:11 angelos Exp $

EAPI=3
inherit qt4-r2

MY_P=${PN}_${PV}_src

DESCRIPTION="A Qt4 client for the music player daemon (MPD) written in C++"
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Quimup"
SRC_URI="mirror://sourceforge/musicpd/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="x11-libs/qt-gui
	>=media-libs/libmpdclient-2.1"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${MY_P}

src_prepare() {
	sed -i -e "/FLAGS/d" ${PN}.pro
}

src_install() {
	dobin ${PN}
	dodoc Changelog FAQ.txt README
}
