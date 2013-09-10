# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-editors/gedit-plugins/gedit-plugins-2.32.0.ebuild,v 1.8 2012/12/16 21:43:34 tetromino Exp $

EAPI="3"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
PYTHON_DEPEND="python? 2:2.6"
PYTHON_USE_WITH="xml"
PYTHON_USE_WITH_OPT="python"

inherit gnome2 multilib python eutils

DESCRIPTION="Offical plugins for gedit."
HOMEPAGE="http://live.gnome.org/GeditPlugins"

LICENSE="GPL-2+"
KEYWORDS="amd64 x86"
SLOT="0"

IUSE_plugins="charmap synctex terminal"
IUSE="+python ${IUSE_plugins}"

RDEPEND=">=x11-libs/gtk+-2.14:2
	gnome-base/gconf
	>=x11-libs/gtksourceview-2.6:2.0
	>=app-editors/gedit-2.29.3[python]
	>=dev-python/pygtk-2.14:2
	python? ( >=dev-python/pygtksourceview-2.2:2 )
	charmap? ( >=gnome-extra/gucharmap-2.23.0:0 )
	synctex? ( >=dev-python/dbus-python-0.82 )
	terminal? (
		dev-python/gconf-python
		>=x11-libs/vte-0.19.4:0[python]
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	dev-util/intltool"

pkg_setup() {
	DOCS="AUTHORS NEWS ChangeLog*"

	# DEFAULT_PLUGINS from configure.ac
	# FIXME: 'taglist' breaks configure
	local myplugins="bookmarks,showtabbar,drawspaces,wordcompletion"

	# python plugins with no extra dependencies beyond what USE=python brings
	use python && myplugins="${myplugins},bracketcompletion,codecomment,colorpicker,commander,joinlines,multiedit,textsize,sessionsaver,smartspaces"

	# python plugins with extra dependencies
	for plugin in ${IUSE_plugins/+}; do
		use ${plugin} || continue
		# FIXME: put in REQUIRED_USE when python.eclass supports EAPI4
		if use python; then
			myplugins="${myplugins},${plugin}"
		else
			ewarn "Plugin '${plugin}' auto-disabled due to USE=-python"
		fi
	done

	G2CONF="${G2CONF}
		--disable-dependency-tracking
		--with-plugins=${myplugins}
		$(use_enable python)"

	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	gnome2_src_prepare

	# disable pyc compiling
	mv py-compile py-compile.orig
	ln -s $(type -P true) py-compile
}

pkg_postinst() {
	gnome2_pkg_postinst
	if use python; then
		python_need_rebuild
		python_mod_optimize /usr/$(get_libdir)/gedit-2/plugins
	fi
}

pkg_postrm() {
	gnome2_pkg_postrm
	use python && python_mod_cleanup /usr/$(get_libdir)/gedit-2/plugins
}
