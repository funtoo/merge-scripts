# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-magnatune/gmpc-magnatune-0.20.0.ebuild,v 1.1 2010/05/25 09:30:50 angelos Exp $

EAPI=2

DESCRIPTION="This plugin allows you to browse and preview available albums on magnatune.com"
HOMEPAGE="http://gmpc.wikia.com/wiki/GMPC_PLUGIN_MAGNATUNE"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="nls"

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2
	x11-libs/gtk+:2[jpeg]
	dev-db/sqlite:3
	>=gnome-base/libglade-2"
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
