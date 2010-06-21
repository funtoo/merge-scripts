# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-editors/gedit-plugins/gedit-plugins-2.28.0.ebuild,v 1.2 2010/03/08 23:44:07 eva Exp $

EAPI="2"
GCONF_DEBUG="no"

inherit gnome2 multilib python

DESCRIPTION="Offical plugins for gedit."
HOMEPAGE="http://live.gnome.org/GeditPlugins"

LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
SLOT="0"

IUSE="bookmarks +bracketcompletion charmap colorpicker +drawspaces +joinlines python +session showtabbar smartspaces terminal"

RDEPEND=">=x11-libs/gtk+-2.14
		gnome-base/gconf
		>=x11-libs/gtksourceview-2.6
		>=app-editors/gedit-2.26.1[python]
		>=dev-python/pygtk-2.14
		charmap? (
			>=gnome-extra/gucharmap-2.24.3
		)
		session? (
			dev-lang/python[xml]
		)
		python? (
			>=dev-python/pygtksourceview-2.2.0
		)
		terminal? (
			>=x11-libs/vte-0.19.4[python]
		)"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	dev-util/intltool"

DOCS="AUTHORS NEWS ChangeLog*"

pkg_setup() {
	local myplugins="codecomment"

	for plugin in ${IUSE/python}; do
		if use session && [ "${plugin/+}" = "session" ]; then
			myplugins="${myplugins},sessionsaver"
		elif use ${plugin/+}; then
			myplugins="${myplugins},${plugin/+}"
		fi
	done

	G2CONF="${G2CONF}
		--disable-dependency-tracking
		--with-plugins=${myplugins}
		$(use_enable python)"
}

src_prepare() {
	gnome2_src_prepare

	# disable pyc compiling
	mv py-compile py-compile.orig
	ln -s $(type -P true) py-compile

	# Fix intltoolize broken file, see upstream #577133
	sed "s:'\^\$\$lang\$\$':\^\$\$lang\$\$:g" -i po/Makefile.in.in \
		|| die "sed failed"
}

src_test() {
	emake check || die "make check failed"
}

src_install() {
	gnome2_src_install
	# gedit doesn't rely on *.la files
	find "${D}" -name "*.la" -delete || die "*.la files removal failed"
}

pkg_postinst() {
	gnome2_pkg_postinst
	python_need_rebuild
	python_mod_optimize /usr/$(get_libdir)/gedit-2/plugins
}

pkg_postrm() {
	gnome2_pkg_postrm
	python_mod_cleanup /usr/$(get_libdir)/gedit-2/plugins
}
