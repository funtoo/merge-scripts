# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-tagedit/gmpc-tagedit-0.20.0.ebuild,v 1.1 2010/05/25 09:26:54 angelos Exp $

EAPI=2

DESCRIPTION="This plugin allows you to edit tags in your library"
HOMEPAGE="http://gmpc.wikia.com/wiki/GMPC_PLUGIN_TAGEDIT"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="nls"

RDEPEND=">=media-sound/gmpc-${PV}
	media-libs/taglib
	dev-libs/libxml2"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	dev-util/gob
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
