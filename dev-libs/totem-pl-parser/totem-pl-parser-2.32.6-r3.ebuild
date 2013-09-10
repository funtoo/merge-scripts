# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/totem-pl-parser/totem-pl-parser-2.32.6-r3.ebuild,v 1.9 2013/04/01 18:24:12 ago Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit autotools eutils gnome2

DESCRIPTION="Playlist parsing library"
HOMEPAGE="http://projects.gnome.org/totem/ http://developer.gnome.org/totem-pl-parser/stable/"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="alpha amd64 arm ia64 ~ppc ~ppc64 sparc x86 ~x86-fbsd"
IUSE="archive +introspection +quvi"

RDEPEND=">=dev-libs/glib-2.24:2
	dev-libs/gmime:2.6
	>=net-libs/libsoup-gnome-2.30:2.4
	archive? ( >=app-arch/libarchive-2.8.4 )
	introspection? ( >=dev-libs/gobject-introspection-0.9.5 )
	quvi? ( >=media-libs/libquvi-0.2.15 )"
DEPEND="${RDEPEND}
	!<media-video/totem-2.21
	dev-libs/gobject-introspection-common
	>=dev-util/intltool-0.35
	dev-util/gtk-doc-am
	gnome-base/gnome-common
	>=sys-devel/gettext-0.17
	virtual/pkgconfig"
# eautoreconf needs:
#	dev-libs/gobject-introspection-common
#	gnome-base/gnome-common

src_prepare() {
	G2CONF="${G2CONF}
		--disable-static
		$(use_enable archive libarchive)
		$(use_enable quvi)
		$(use_enable introspection)"
	DOCS="AUTHORS ChangeLog NEWS"

	# bug #386651, https://bugzilla.gnome.org/show_bug.cgi?id=661451
	epatch "${FILESDIR}/${PN}-2.32.6-quvi-0.4.patch"

	# build: Use gmime-2.6 (fixed in 'master' (> 3.4.3))
	epatch "${FILESDIR}/${PN}-2.32.6-gmime26.patch"

	# Disable tests requiring network access, bug #346127
	sed -e 's:\(g_test_add_func.*/parser/resolution.*\):/*\1*/:' \
		-e 's:\(g_test_add_func.*/parser/parsing/itms_link.*\):/*\1*/:' \
		-i plparse/tests/parser.c || die "sed failed"

	eautoreconf
	gnome2_src_prepare
}

src_test() {
	# This is required as told by upstream in bgo#629542
	dbus-launch emake check || die "emake check failed"
}
