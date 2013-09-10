# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-editors/gedit-plugins/gedit-plugins-3.8.2.ebuild,v 1.1 2013/05/26 11:05:42 pacho Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes" # plugins are dlopened
PYTHON_COMPAT=( python3_2 )
PYTHON_REQ_USE="xml"

inherit eutils gnome2 multilib python-r1

DESCRIPTION="Official plugins for gedit"
HOMEPAGE="http://live.gnome.org/GeditPlugins"

LICENSE="GPL-2+"
KEYWORDS="~amd64 ~x86"
SLOT="0"

IUSE_plugins="charmap terminal"
IUSE="+python ${IUSE_plugins}"
REQUIRED_USE="charmap? ( python ) terminal? ( python )"

RDEPEND="
	>=app-editors/gedit-3.7.1[python?]
	>=dev-libs/glib-2.32:2
	>=dev-libs/libpeas-1.7.0[gtk,python?]
	>=x11-libs/gtk+-3.4:3
	>=x11-libs/gtksourceview-3:3.0
	python? (
		${PYTHON_DEPS}
		>=app-editors/gedit-3[introspection,${PYTHON_USEDEP}]
		dev-libs/libpeas[${PYTHON_USEDEP}]
		dev-python/dbus-python[${PYTHON_USEDEP}]
		dev-python/pycairo
		dev-python/pygobject:3[cairo,${PYTHON_USEDEP}]
		>=x11-libs/gtk+-3.4:3[introspection]
		>=x11-libs/gtksourceview-3:3.0[introspection]
		x11-libs/pango[introspection]
		x11-libs/gdk-pixbuf:2[introspection]
	)
	charmap? ( >=gnome-extra/gucharmap-3:2.90[introspection] )
	terminal? ( x11-libs/vte:2.90[introspection] )
"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.40.0
	sys-devel/gettext
	virtual/pkgconfig
"

src_configure() {
	# DEFAULT_PLUGINS from configure.ac
	local myplugins="bookmarks,drawspaces,wordcompletion"

	# python plugins with no extra dependencies beyond what USE=python brings
	use python && myplugins="${myplugins},bracketcompletion,codecomment,colorpicker,colorschemer,commander,dashboard,joinlines,multiedit,textsize,smartspaces,synctex"

	# python plugins with extra dependencies
	for plugin in ${IUSE_plugins/+}; do
		use ${plugin} && myplugins="${myplugins},${plugin}"
	done

	gnome2_src_configure \
		--with-plugins=${myplugins} \
		$(use_enable python)
}
