# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/scmpc/scmpc-0.2.2.ebuild,v 1.6 2008/11/05 18:44:45 angelos Exp $

DESCRIPTION="a client for MPD which submits your tracks to last.fm"
HOMEPAGE="http://scmpc.berlios.de/"
SRC_URI="mirror://berlios/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="net-misc/curl
	dev-libs/argtable
	dev-libs/confuse
	dev-libs/libdaemon"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_install() {
	make DESTDIR="${D}" install || die "install failed"

	newinitd "${FILESDIR}/scmpc.init" ${PN}
}
