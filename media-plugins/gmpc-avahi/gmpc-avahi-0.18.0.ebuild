# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-avahi/gmpc-avahi-0.18.0.ebuild,v 1.4 2009/08/09 11:39:01 nixnut Exp $

DESCRIPTION="This plugin discovers avahi enabled mpd servers"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/Avahi"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2
	net-dns/avahi"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_install () {
	emake DESTDIR="${D}" install || die
}
