# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/mpdscribble/mpdscribble-0.17.ebuild,v 1.4 2009/08/17 20:35:18 fauli Exp $

EAPI=1

DESCRIPTION="An MPD client that submits information to Audioscrobbler"
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Mpdscribble"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~hppa ~ppc sparc x86"
IUSE=""

RDEPEND="dev-libs/glib:2
	|| ( >=dev-libs/glib-2.16:2
		dev-libs/libgcrypt )
	net-libs/libsoup:2.4"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	newinitd "${FILESDIR}/mpdscribble.rc" mpdscribble
	chmod 600 "${D}"/etc/mpdscribble.conf
	dodoc AUTHORS NEWS README
	rm -r -f "${D}"/usr/share/doc/${PN}
	dodir /var/cache/mpdscribble
}
