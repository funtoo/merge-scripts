# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2
inherit subversion autotools

DESCRIPTION="A Window Maker dock app client for Music Player Daemon(media-sound/mpd)"
HOMEPAGE="http://mpd.wikia.com/index.php?title=Client:WMmp&oldid=941"
LICENSE="GPL-2"

ESVN_REPO_URI="https://svn.musicpd.org/WMmp/trunk/"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""
S="${WORKDIR}/${P/wm/WM}"

DEPEND="x11-libs/libXext
	x11-libs/libXpm"

src_prepare() {
	eautoreconf
}

src_install () {
	emake install DESTDIR=${D} || die

	dodoc AUTHORS README THANKS TODO
}
