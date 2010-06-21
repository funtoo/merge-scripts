# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-editors/gedit-plugins/gedit-plugins-2.30.0.ebuild,v 1.1 2010/06/18 13:10:29 pacho Exp $

EAPI="2"
GCONF_DEBUG="no"

inherit gnome2 multilib python eutils

DESCRIPTION="Offical plugins for gedit."
HOMEPAGE="http://live.gnome.org/GeditPlugins"

LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
SLOT="0"

IUSE="bookmarks +bracketcompletion charmap colorpicker +drawspaces +joinlines python +session showtabbar smartspaces terminal"

RDEPEND=">=x11-libs/gtk+-2.14
		gnome-base/gconf
		>=x11-libs/gtksourceview-2.6
		>=app-editors/gedit-2.29.3[python]
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

	# Fix issues with find/replace in selections
	epatch "${FILESDIR}/${P}-find-replace.patch"

	# Add Ctrl+Shift+C/V copy paste accelerators to terminal
	epatch "${FILESDIR}/${P}-copy-paste.patch"

	# Improved handling of scrolling for replace-all command
	epatch "${FILESDIR}/${P}-replace-all.patch"

	# Fix background color of the commander entry
	epatch "${FILESDIR}/${P}-background-color.patch"

	# Make multi edit keybinding toggle multi edit mode
	epatch "${FILESDIR}/${P}-keybinding-toggle.patch"

	# Make multi edit menu item proper toggle item
	epatch "${FILESDIR}/${P}-edit-menu.patch"

	# Added commander toggle menu item
	epatch "${FILESDIR}/${P}-commander-menu.patch"

	# disable pyc compiling
	mv py-compile py-compile.orig
	ln -s $(type -P true) py-compile
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
