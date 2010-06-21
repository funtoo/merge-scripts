# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/mpdas/mpdas-0.2.4.ebuild,v 1.2 2009/05/20 17:57:12 ssuominen Exp $

inherit toolchain-funcs

DESCRIPTION="An AudioScrobbler client for MPD written in C++"
HOMEPAGE="http://50hz.ws/mpdas/"
SRC_URI="http://50hz.ws/mpdas/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="media-libs/libmpd
	net-misc/curl"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_compile() {
	tc-export CXX
	emake CONFIG="/etc" || die "emake failed"
}

src_install() {
	dobin ${PN} || die "dobin failed"
	doman ${PN}.1
	dodoc ChangeLog mpdasrc.example README
}

pkg_postinst() {
	elog "For further configuration help consult the README in"
	elog "/usr/share/doc/${PF}"
}
