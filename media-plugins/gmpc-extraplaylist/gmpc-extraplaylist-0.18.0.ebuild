# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-extraplaylist/gmpc-extraplaylist-0.18.0.ebuild,v 1.4 2009/06/09 19:04:57 fauli Exp $

DESCRIPTION="This plugin adds a second pane showing the playlist"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/Extra_playlist"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_install () {
	emake DESTDIR="${D}" install || die
}
