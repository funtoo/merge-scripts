# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/gmpc/gmpc-0.20.0.ebuild,v 1.1 2010/05/19 13:31:50 angelos Exp $

EAPI=2
inherit gnome2-utils

DESCRIPTION="A GTK+2 client for the Music Player Daemon"
HOMEPAGE="http://gmpc.wikia.com/wiki/Gnome_Music_Player_Client"
SRC_URI="http://download.sarine.nl/Programs/${PN}/${PV}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc ~x86"
IUSE="nls xspf"

RDEPEND=">=dev-libs/glib-2.16:2
	>=x11-libs/gtk+-2.12:2
	x11-libs/libsexy
	>=gnome-base/libglade-2
	>=media-libs/libmpd-0.19.2
	net-libs/libsoup:2.4
	dev-db/sqlite:3
	xspf? ( >=media-libs/libxspf-1.2 )"
DEPEND="${RDEPEND}
	dev-lang/vala
	dev-util/gob
	dev-util/pkgconfig
	nls? ( dev-util/intltool
		sys-devel/gettext )"

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable nls) \
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
