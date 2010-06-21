# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-alarm/gmpc-alarm-0.20.0.ebuild,v 1.1 2010/05/24 13:43:52 angelos Exp $

EAPI=2

DESCRIPTION="This plugin can start/stop/pause your music at a preset time"
HOMEPAGE="http://gmpc.wikia.com/wiki/GMPC_PLUGIN_ALARM"
SRC_URI="http://download.sarine.nl/Programs/gmpc/${PV}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="nls"

RDEPEND=">=media-sound/gmpc-${PV}"
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
	dodoc AUTHORS ChangeLog README TODO
}
