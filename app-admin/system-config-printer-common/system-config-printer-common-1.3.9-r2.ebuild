# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/system-config-printer-common/system-config-printer-common-1.3.9-r2.ebuild,v 1.4 2012/07/18 21:11:29 dilfridge Exp $

EAPI="3"

PYTHON_DEPEND="2"
WANT_AUTOMAKE="1.11"
inherit eutils python autotools

MY_P="${PN%-common}-${PV}"

DESCRIPTION="Common modules of Red Hat's printer administration tool"
HOMEPAGE="http://cyberelk.net/tim/software/system-config-printer/"
SRC_URI="http://cyberelk.net/tim/data/system-config-printer/1.3/${MY_P}.tar.xz"

LICENSE="GPL-2"
KEYWORDS="alpha amd64 arm ~hppa ia64 ppc ppc64 sh sparc x86"
SLOT="0"
IUSE="doc policykit"

# Needs cups running, bug 284005
RESTRICT="test"

# system-config-printer split since 1.1.3
COMMON_DEPEND="
	dev-libs/glib:2
	dev-libs/libxml2[python]
	dev-python/dbus-python
	>=dev-python/pycups-1.9.60
	dev-python/pycurl
	>=dev-python/pygobject-2.21.5:2
	<net-print/cups-1.6.0[dbus]
	>=sys-fs/udev-164-r2
	virtual/libusb:0
"
DEPEND="${COMMON_DEPEND}
	dev-util/intltool
	virtual/pkgconfig
	doc? ( dev-python/epydoc )
"
RDEPEND="${COMMON_DEPEND}
	!<app-admin/system-config-printer-gnome-${PV}
	policykit? ( sys-auth/polkit )
"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	python_set_active_version 2
}

src_prepare() {
	epatch "${FILESDIR}/${PN}-1.3.9-split.patch"
	epatch "${FILESDIR}/${PN}-1.3.9-cups_filters_path.patch"
	eautoreconf
}

src_configure() {
	econf \
		--disable-nls \
		--with-udev-rules
}

src_compile() {
	emake || die "emake failed"
	if use doc; then
		emake html || die "emake html failed"
	fi
}

src_install() {
	dodoc AUTHORS ChangeLog README || die "dodoc failed"

	if use doc; then
		dohtml -r html/ || die "installing html docs failed"
	fi

	emake DESTDIR="${ED}" install \
		udevrulesdir=/lib/udev/rules.d \
		udevhelperdir=/lib/udev \
		|| die "emake install failed"

	python_convert_shebangs -q -r $(python_get_version) "${ED}"
}

pkg_postinst() {
	python_mod_optimize cupshelpers
}

pkg_postrm() {
	python_mod_cleanup cupshelpers /usr/share/system-config-printer
}
