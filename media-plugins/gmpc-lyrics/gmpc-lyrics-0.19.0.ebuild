# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-lyrics/gmpc-lyrics-0.19.0.ebuild,v 1.2 2009/09/27 12:50:59 ssuominen Exp $

EAPI=2

DESCRIPTION="This plugin fetches lyrics"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/Lyrics"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="nls"

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2"
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
