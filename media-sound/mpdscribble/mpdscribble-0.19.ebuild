# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/mpdscribble/mpdscribble-0.19.ebuild,v 1.5 2010/06/01 08:05:27 phajdan.jr Exp $

EAPI=2
inherit autotools eutils

DESCRIPTION="An MPD client that submits information to Audioscrobbler"
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Mpdscribble"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~hppa ~ppc ~sparc x86"
IUSE="+curl"

RDEPEND=">=dev-libs/glib-2.16:2
	media-libs/libmpdclient
	curl? ( net-misc/curl )
	!curl? ( net-libs/libsoup:2.4 )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.18-ldadd_gthread.patch
	eautoreconf
}

src_configure() {
	local myclient=soup
	use curl && myclient=curl
	econf \
		--disable-dependency-tracking \
		--with-http-client=${myclient}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	newinitd "${FILESDIR}/mpdscribble.rc" mpdscribble
	chmod 600 "${D}"/etc/mpdscribble.conf
	dodoc AUTHORS NEWS README
	rm -r -f "${D}"/usr/share/doc/${PN}
	dodir /var/cache/mpdscribble
}
