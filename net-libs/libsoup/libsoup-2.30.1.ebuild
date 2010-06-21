# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libsoup/libsoup-2.30.1.ebuild,v 1.3 2010/06/20 14:05:16 ford_prefect Exp $

EAPI="2"

inherit autotools eutils gnome2

DESCRIPTION="An HTTP library implementation in C"
HOMEPAGE="http://www.gnome.org/"
SRC_URI="${SRC_URI}
	mirror://gentoo/${P}-build-gir-patches.tar.bz2"

LICENSE="LGPL-2"
SLOT="2.4"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd"
# Do NOT build with --disable-debug/--enable-debug=no - gnome2.eclass takes care of that
IUSE="debug doc +introspection gnome ssl"

RDEPEND=">=dev-libs/glib-2.21.3
	>=dev-libs/libxml2-2
	introspection? ( >=dev-libs/gobject-introspection-0.6.7 )
	ssl? ( >=net-libs/gnutls-2.1.7 )"
DEPEND="${RDEPEND}
	>=dev-util/pkgconfig-0.9
	dev-util/gtk-doc-am
	doc? ( >=dev-util/gtk-doc-1 )"
#	test? (
#		www-servers/apache
#		dev-lang/php
#		net-misc/curl )
PDEPEND="gnome? ( ~net-libs/${PN}-gnome-${PV} )"

DOCS="AUTHORS NEWS README"

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-static
		--without-gnome
		$(use_enable introspection)
		$(use_enable ssl)"
}

src_prepare() {
	gnome2_src_prepare

	# Fix test to follow POSIX (for x86-fbsd)
	# No patch to prevent having to eautoreconf
	sed -e 's/\(test.*\)==/\1=/g' -i configure.ac configure || die "sed failed"

	# Patch *must* be applied conditionally (see patch for details)
	if use doc; then
		# Fix bug 268592 (build fails !gnome && doc)
		epatch "${FILESDIR}/${P}-fix-build-without-gnome-with-doc.patch"
	fi

	if use introspection; then
		epatch "${WORKDIR}/${P}-build-gir-1.patch"
		epatch "${WORKDIR}/${P}-build-gir-2.patch"
	fi

	eautoreconf
}
