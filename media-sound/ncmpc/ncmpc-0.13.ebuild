# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/ncmpc/ncmpc-0.13.ebuild,v 1.7 2009/05/22 13:42:04 ssuominen Exp $

EAPI=2
inherit multilib

DESCRIPTION="A ncurses client for the Music Player Daemon (MPD)"
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Ncmpc"
SRC_URI="http://downloads.sourceforge.net/musicpd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 hppa ppc ~ppc64 sparc x86 ~x86-fbsd"
IUSE="artist-screen colors debug +help-screen key-screen lyrics-screen
mouse nls search-screen song-screen"
#lirc

RDEPEND=">=dev-libs/glib-2.4:2
	dev-libs/popt
	sys-libs/ncurses"
#	lirc? ( app-misc/lirc )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_configure() {
	# The use_with lyrics-screen is for multilib
	# USE lirc is broken wrt #250015
	# $(use_enable lirc) \
	econf \
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
	emake DESTDIR="${D}" install || die "emake install failed"
}
