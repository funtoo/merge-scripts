# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="2"

inherit git autotools

DESCRIPTION="A ncurses client for the Music Player Daemon (MPD)"
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Ncmpc"
LICENSE="GPL-2"
EGIT_REPO_URI="git://git.musicpd.org/cirrus/ncmpc.git"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE="artist-screen +colors debug key-screen lirc lyrics-screen minimal mouse nls outputs-screen search-screen +wide"

RDEPEND=">=dev-libs/glib-2.4
	dev-libs/popt
	sys-libs/ncurses
	lirc? ( app-misc/lirc )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	eautoreconf
	glib-gettextize --force --copy
}

src_configure() {
	econf \
		$(use_enable artist-screen) \
		$(use_enable colors) \
		$(use_enable debug) \
		$(use_enable help-screen) \
		$(use_enable key-screen) \
		$(use_enable lirc) \
		$(use_enable lyrics-screen) \
		$(use_enable minimal mini) \
		$(use_enable mouse) \
		$(use_enable nls) \
		$(use_enable outputs-screen) \
		$(use_enable search-screen) \
		$(use_enable wcwidth wide) || die "econf failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
}
