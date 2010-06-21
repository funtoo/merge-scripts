# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-osd/gmpc-osd-0.18.0.ebuild,v 1.5 2009/06/09 19:07:05 fauli Exp $

DESCRIPTION="This plugin provides an on-screen-display using xosd"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/Osd"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc sparc x86"
IUSE=""

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2
	x11-libs/xosd"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_install () {
	emake DESTDIR="${D}" install || die
}
