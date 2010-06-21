# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2
ESVN_REPO_URI="svn://svn.berlios.de/gimmix/trunk/src"
inherit subversion autotools

DESCRIPTION="Gimmix is a graphical music player daemon (MPD) client written in C using GTK+2."
HOMEPAGE="http://gimmix.berlios.de/"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""

RDEPEND=">=x11-libs/gtk+-2.10
	>=gnome-base/libglade-2.6
	x11-libs/libnotify
	media-libs/libmpd
	dev-libs/confuse
	net-libs/libnxml"
DEPEND="${RDEPEND}"

src_prepare() {
	eautoreconf
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
}
