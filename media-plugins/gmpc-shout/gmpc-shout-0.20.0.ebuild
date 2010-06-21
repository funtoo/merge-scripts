# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-shout/gmpc-shout-0.20.0.ebuild,v 1.1 2010/05/25 10:03:32 angelos Exp $

EAPI=2

DESCRIPTION="This plugin calls ogg123 and points it at mpd's shoutstream"
HOMEPAGE="http://gmpc.wikia.com/wiki/GMPC_PLUGIN_SHOUT"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="nls"

RDEPEND=">=media-sound/gmpc-${PV}
	media-sound/vorbis-tools[ogg123]
	dev-libs/libxml2
	x11-libs/cairo"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	nls? ( dev-util/intltool
		sys-devel/gettext )"

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable nls)
}

src_install() {
	emake DESTDIR="${D}" install || die
}
