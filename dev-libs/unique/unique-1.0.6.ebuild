# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit gnome2

DESCRIPTION="a library for writing single instance application"
HOMEPAGE="http://live.gnome.org/LibUnique"
SRC_URI="http://www.gnome.org/~ebassi/source/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="dbus debug doc"

RDEPEND=">=dev-libs/glib-2.12.0
	>=x11-libs/gtk+-2.11.0
	x11-libs/libX11
	dbus? ( >=dev-libs/dbus-glib-0.70 )"
DEPEND="${RDEPEND}
	sys-devel/gettext
	>=dev-util/pkgconfig-0.17
	doc? ( >=dev-util/gtk-doc-1.6 )"

DOCS="AUTHORS NEWS ChangeLog README TODO"

# FIXME: automagic dbus dependency
pkg_setup() {
	G2CONF="${G2CONF}
		$(use_enable dbus)
		$(use_enable debug)"
}
