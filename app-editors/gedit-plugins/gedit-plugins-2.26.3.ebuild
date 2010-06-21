# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-editors/gedit-plugins/gedit-plugins-2.26.3.ebuild,v 1.1 2009/08/27 17:11:49 mrpouet Exp $

EAPI="2"
GCONF_DEBUG="no"

inherit gnome2

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

DOCS="AUTHORS NEWS"

pkg_setup()
{
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

src_test() {
	emake check || die "make check failed"
}
