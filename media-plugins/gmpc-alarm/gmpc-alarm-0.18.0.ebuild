# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-alarm/gmpc-alarm-0.18.0.ebuild,v 1.5 2009/06/09 19:01:36 fauli Exp $

EAPI=2
inherit autotools eutils

DESCRIPTION="This plugin can start/stop/pause your music at a preset time"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/Alarm"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2"
DEPEND="${RDEPEND}
	sys-apps/sed
	dev-util/pkgconfig"

src_prepare() {
	sed -i -e 's:-Werror::' src/Makefile.am || die "sed failed"
	eautoreconf
}

src_install () {
	emake DESTDIR="${D}" install || die "emake install failed"
}
