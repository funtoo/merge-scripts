# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-mdcover/gmpc-mdcover-0.20.0.ebuild,v 1.1 2010/05/25 09:56:22 angelos Exp $

EAPI=2

DESCRIPTION="This plugin fetches cover art, artist art, album and artist information from the file system"
HOMEPAGE="http://gmpc.wikia.com/wiki/GMPC_PLUGIN_MDCOVER"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="nls"

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2
	x11-libs/gtk+:2[jpeg]"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	nls? ( dev-util/intltool
		sys-devel/gettext )"

src_configure() {
	econf \
		$(use_enable nls) \
		--disable-dependency-tracking
}

src_install() {
	emake DESTDIR="${D}" install || die
}
