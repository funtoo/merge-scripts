# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/gmpc/gmpc-0.19.1.ebuild,v 1.1 2009/11/03 18:49:59 angelos Exp $

EAPI=2
inherit gnome2-utils

DESCRIPTION="A GTK+2 client for the Music Player Daemon"
HOMEPAGE="http://gmpcwiki.sarine.nl/index.php/GMPC"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="nls xspf"

RDEPEND="sys-libs/zlib
	>=dev-libs/glib-2.16:2
	>=x11-libs/gtk+-2.12:2
	x11-libs/libsexy
	>=gnome-base/libglade-2
	>=media-libs/libmpd-0.18.1
	net-libs/libsoup:2.4
	dev-db/sqlite:3
	x11-libs/libSM
	x11-libs/libICE
	xspf? ( >=media-libs/libxspf-1.2 )"
DEPEND="${RDEPEND}
	dev-util/gob
	dev-util/pkgconfig
	nls? ( dev-util/intltool
		sys-devel/gettext )"

src_configure() {
	econf \
		$(use_enable nls) \
		--disable-dependency-tracking \
		$(use_enable xspf libxspf) \
		--disable-libspiff \
		--enable-system-libsexy
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README
}

pkg_preinst() { gnome2_icon_savelist; }
pkg_postinst() { gnome2_icon_cache_update; }
pkg_postrm() { gnome2_icon_cache_update; }
