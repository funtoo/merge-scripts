# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-cdr/acetoneiso/acetoneiso-2.2.1.ebuild,v 1.5 2010/02/11 09:51:14 ssuominen Exp $

EAPI=2
MY_P=${PN}_${PV}

inherit flag-o-matic qt4-r2

DESCRIPTION="a feature-rich and complete software application to manage CD/DVD images"
HOMEPAGE="http://www.acetoneteam.org/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="x11-libs/qt-gui:4
	x11-libs/qt-core:4
	x11-libs/qt-webkit:4
	x11-libs/qt-xmlpatterns:4
	media-sound/phonon"
RDEPEND="${DEPEND}
	sys-fs/fuseiso"

S=${WORKDIR}/${MY_P}/${PN}

DOCS="AUTHORS CHANGELOG FEATURES README"
DOCSDIR="${WORKDIR}/${MY_P}"

src_prepare() {
	sed -i -e 's:unrar-nonfree:unrar:g' sources/compress.h locale/*.ts || die
}

src_configure() {
	append-flags -I/usr/include/KDE
	qt4-r2_src_configure
}
