# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-avahi/gmpc-avahi-0.19.0.ebuild,v 1.1 2009/09/27 12:22:14 ssuominen Exp $

EAPI=2

DESCRIPTION="This plugin discovers avahi enabled mpd servers"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/Avahi"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="nls"

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2
	net-dns/avahi[dbus]"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	nls? ( dev-util/intltool
		sys-devel/gettext )"

src_configure() {
	econf \
		$(use_enable nls) \
		--disable-dependency-tracking
}

src_install () {
	emake DESTDIR="${D}" install || die
}
