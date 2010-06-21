# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gmpc-magnatune/gmpc-magnatune-0.18.0.ebuild,v 1.5 2009/06/09 19:08:37 fauli Exp $

EAPI=2

DESCRIPTION="This plugin allows you to browse and preview available albums on magnatune.com"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/Magnatune"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc sparc x86"
IUSE=""

RDEPEND=">=media-sound/gmpc-${PV}
	dev-libs/libxml2
	x11-libs/gtk+:2[jpeg]"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_install () {
	emake DESTDIR="${D}" install || die "emake install failed"
}
