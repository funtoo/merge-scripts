# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/ncmpc/ncmpc-0.16.1-r1.ebuild,v 1.1 2010/06/03 19:09:26 angelos Exp $

EAPI=2
inherit base multilib

DESCRIPTION="A ncurses client for the Music Player Daemon (MPD)"
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Ncmpc"
SRC_URI="http://downloads.sourceforge.net/musicpd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="artist-screen colors debug +help-screen key-screen lyrics-screen
mouse nls search-screen song-screen"
#lirc

RDEPEND=">=dev-libs/glib-2.12:2
	dev-libs/popt
	media-libs/libmpdclient"
#	lirc? ( app-misc/lirc )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

PATCHES=( "${FILESDIR}/${P}-lyrics-backtrace.patch" )

src_configure() {
	# The use_with lyrics-screen is for multilib
	# USE lirc is broken wrt #250015
	# $(use_enable lirc) \
	econf \
		--docdir=${EPREFIX}/usr/share/doc/${PF} \
		--disable-dependency-tracking \
		$(use_enable artist-screen) \
		$(use_enable colors) \
		$(use_enable debug) \
		$(use_enable help-screen) \
		$(use_enable key-screen) \
		$(use_enable lyrics-screen) \
		$(use_with lyrics-screen lyrics-plugin-dir /usr/$(get_libdir)/ncmpc/lyrics) \
		$(use_enable mouse) \
		$(use_enable nls) \
		$(use_enable nls locale) \
		$(use_enable nls multibyte) \
		$(use_enable search-screen) \
		$(use_enable song-screen)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS NEWS README doc/config.sample doc/keys.sample
}
