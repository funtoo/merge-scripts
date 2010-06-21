# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-playlistsort/gmpc-playlistsort-0.17.0.ebuild,v 1.4 2009/03/20 17:24:23 ranger Exp $

DESCRIPTION="This plugin adds a dialog to sort the current playlist"
HOMEPAGE="http://gmpcwiki.sarine.nl/"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_install () {
	emake DESTDIR="${D}" install || die "emake failed"
}
