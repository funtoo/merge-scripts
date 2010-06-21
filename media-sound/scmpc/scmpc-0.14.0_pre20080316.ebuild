# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/scmpc/scmpc-0.14.0_pre20080316.ebuild,v 1.1 2009/03/16 19:07:14 angelos Exp $

EAPI=1

DESCRIPTION="a client for MPD which submits your tracks to last.fm"
HOMEPAGE="http://ngls.zakx.de/scmpc/"
SRC_URI="http://ngls.zakx.de/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="dev-libs/glib:2
	dev-libs/confuse
	net-misc/curl"

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS NEWS README scmpc.conf.example
	newinitd "${FILESDIR}"/${PN}-2.init ${PN}
	insinto /etc
	insopts -m600
	newins scmpc.conf.example scmpc.conf
}

pkg_postinst() {
	elog "Note: This version of scmpc requires mpd-0.14"
}
