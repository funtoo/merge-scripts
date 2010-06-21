# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2
EGIT_REPO_URI="git://git.musicpd.org/master/mpc.git"
inherit git autotools bash-completion

DESCRIPTION="A commandline client for Music Player Daemon (media-sound/mpd)"
HOMEPAGE="http://mpd.wikia.com/index.php?title=Client:Mpc&oldid=4111"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE="nls"

DEPEND="nls? ( || ( sys-libs/glibc dev-libs/libiconv ) )
	dev-util/gperf"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf --disable-dependency-tracking \
		$(use_enable nls iconv)
}

src_install() {
	dobin doc/mpd-m3u-handler.sh
	dobin doc/mpd-pls-handler.sh
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog README

	dobashcompletion doc/mpc-bashrc
}
