# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

GCONF_DEBUG="no"
inherit gnome2

DESCRIPTION="A canvas library based on GTK+-2, Cairo, and Pango"
HOMEPAGE="http://developer.mugshot.org/wiki/Hippo_Canvas"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="doc python"

RDEPEND=">=dev-libs/glib-2.6
	>=dev-libs/libcroco-0.6
	>=x11-libs/gtk+-2.6
	>=x11-libs/pango-1.14
	python? ( dev-lang/python
		dev-python/pycairo
		dev-python/pygtk )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.6 )"

DOCS="AUTHORS README TODO"

pkg_setup() {
	G2CONF="$(use_enable python)"
}
