# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2
ESVN_REPO_URI="https://svn.musicpd.org/glurp/trunk/"
inherit subversion autotools

DESCRIPTION="Glurp is a GTK2 based graphical client for the Music Player Daemon"
HOMEPAGE="http://sourceforge.net/projects/glurp/"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE="debug"

DEPEND=">=x11-libs/gtk+-2.4.0
	>=gnome-base/libglade-2.3.6
	!media-sound/glurp-libmpd"

src_prepare() {
        eautoreconf
}

src_configure() {
	econf $(use_enable debug) || die
}

src_install() {
	make DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog
}
