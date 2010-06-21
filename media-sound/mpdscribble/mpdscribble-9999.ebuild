# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2
EGIT_REPO_URI="git://git.musicpd.org/master/mpdscribble.git"
inherit git autotools

DESCRIPTION="An MPD client that submits information to audioscrobbler."
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Mpdscribble"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""

RDEPEND="dev-libs/glib:2
	net-libs/libsoup:2.4"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	eautoreconf
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	newinitd "${FILESDIR}/mpdscribble.rc" mpdscribble
	dodoc AUTHORS NEWS README
	rm -r -f "${D}"/usr/share/doc/${PN}
	dodir /var/cache/mpdscribble
}

pkg_postinst() {
	elog "If you are going to use the init script shipped with this script, you"
	elog "will have to create a config file (/etc/${PN}.conf), see the man page"
	elog "for instructions on how to write one."
}
