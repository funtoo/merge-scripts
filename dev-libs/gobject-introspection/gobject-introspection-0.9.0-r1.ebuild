# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/gobject-introspection/gobject-introspection-0.9.0-r1.ebuild,v 1.1 2010/10/02 14:06:37 eva Exp $

EAPI="3"
GCONF_DEBUG="no"
PYTHON_DEPEND="2:2.5"

inherit eutils gnome2 python

DESCRIPTION="Introspection infrastructure for gobject library bindings"
HOMEPAGE="http://live.gnome.org/GObjectIntrospection/"

LICENSE="LGPL-2 GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~s390 ~sh ~sparc ~x86"
IUSE="doc test"

RDEPEND=">=dev-libs/glib-2.19.0
	virtual/libffi"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	sys-devel/flex
	doc? ( >=dev-util/gtk-doc-1.12 )
	test? ( x11-libs/cairo )"

DOCS="AUTHORS CONTRIBUTORS ChangeLog NEWS README TODO"

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-static
		$(use_enable test tests)"

	python_set_active_version 2
}

src_prepare() {
	# Fix build with python 2.7, bug #327759
	epatch "${FILESDIR}/${P}-python27.patch"

	# FIXME: Parallel compilation failure with USE=doc
	use doc && MAKEOPTS="-j1"

	# Don't pre-compile .py
	ln -sf $(type -P true) py-compile
}

src_install() {
	gnome2_src_install
	find "${ED}" -name "*.la" -delete || die
}

pkg_postinst() {
	python_mod_optimize /usr/$(get_libdir)/${PN}/giscanner
	python_need_rebuild
}

pkg_postrm() {
	python_mod_cleanup /usr/lib*/${PN}/giscanner
}
