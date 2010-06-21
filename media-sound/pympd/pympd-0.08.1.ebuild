# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/pympd/pympd-0.08.1.ebuild,v 1.8 2010/05/28 21:30:24 arfrever Exp $

EAPI=2
inherit eutils toolchain-funcs python multilib gnome2-utils

DESCRIPTION="a Rhythmbox-like PyGTK+ client for Music Player Daemon"
HOMEPAGE="http://sourceforge.net/projects/pympd"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc ~sparc x86"
IUSE=""

RDEPEND=">=virtual/python-2.4
	>=dev-python/pygtk-2.6
	x11-libs/gtk+[jpeg]
	x11-themes/gnome-icon-theme"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	sed -i -e 's:CFLAGS =:CFLAGS +=:' src/modules/tray/Makefile \
		|| die "sed failed"
	sed -i -e 's:\..\/py:/usr/share/pympd/py:g' src/glade/pympd.glade \
		|| die "sed failed"
	epatch "${FILESDIR}"/${P}-desktop-entry.patch
}

src_compile() {
	emake CC="$(tc-getCC)" PREFIX="/usr" DESTDIR="${D}" || die "emake failed"
}

src_install() {
	emake PREFIX="/usr" DESTDIR="${D}" install || die "emake install failed"
	dodoc README
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	python_mod_optimize $(python_get_sitedir)/pympd
	gnome2_icon_cache_update
}

pkg_postrm() {
	python_mod_cleanup $(python_get_sitedir)/pympd
	gnome2_icon_cache_update
}
