# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gnome-menus/gnome-menus-3.0.1-r2.ebuild,v 1.2 2012/12/19 09:55:31 tetromino Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
GNOME_TARBALL_SUFFIX="bz2"

PYTHON_DEPEND="python? 2:2.5"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython 2.7-pypy-*"

inherit autotools eutils gnome2 python

DESCRIPTION="The GNOME menu system, implementing the F.D.O cross-desktop spec"
HOMEPAGE="http://www.gnome.org"

LICENSE="GPL-2+ LGPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"

IUSE="debug python +introspection"

RDEPEND=">=dev-libs/glib-2.18
	introspection? ( >=dev-libs/gobject-introspection-0.9.5 )"
DEPEND="${RDEPEND}
	sys-devel/gettext
	virtual/pkgconfig
	>=dev-util/intltool-0.40

	gnome-base/gnome-common
	dev-libs/gobject-introspection-common"
# eautoreconf requires gnome-common
# The actual menus are provided by slot 3
PDEPEND="gnome-base/gnome-menus:3"

pkg_setup() {
	DOCS="AUTHORS ChangeLog HACKING NEWS README"

	# Do NOT compile with --disable-debug/--enable-debug=no
	# It disables api usage checks
	if ! use debug ; then
		G2CONF="${G2CONF} --enable-debug=minimum"
	fi

	G2CONF="${G2CONF}
		--disable-static
		$(use_enable python)
		$(use_enable introspection)"

	python_pkg_setup
}

src_prepare() {
	# Only build the library (everything else is coming from slot 3)
	epatch "${FILESDIR}/${PN}-3.0.2-library-only.patch"
	# https://bugzilla.gnome.org/show_bug.cgi?id=688972
	epatch "${FILESDIR}/${PN}-3.0.1-applications-merged.patch"
	eautoreconf
	gnome2_src_prepare

	# disable pyc compiling
	python_clean_py-compile_files

	python_copy_sources
}

src_configure() {
	python_execute_function -s gnome2_src_configure
}

src_compile() {
	python_execute_function -s gnome2_src_compile
}

src_test() {
	python_execute_function -s -d
}

src_install() {
	python_execute_function -s gnome2_src_install
	python_clean_installation_image
}

pkg_postinst() {
	gnome2_pkg_postinst
}

pkg_postrm() {
	gnome2_pkg_postrm
}
