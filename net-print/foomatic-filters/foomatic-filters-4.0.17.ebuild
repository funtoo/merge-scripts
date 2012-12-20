# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-print/foomatic-filters/foomatic-filters-4.0.17.ebuild,v 1.2 2012/11/16 14:27:35 scarabeus Exp $

EAPI=4

inherit autotools eutils versionator

DESCRIPTION="Foomatic wrapper scripts"
HOMEPAGE="http://www.linuxprinting.org/foomatic.html"
SRC_URI="http://www.openprinting.org/download/foomatic/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="cups dbus"

RDEPEND="
	dev-lang/perl
	app-text/ghostscript-gpl
	cups? ( >=net-print/cups-1.1.19 )
	!cups? (
		|| (
			app-text/enscript
			app-text/a2ps
			app-text/mpage
		)
	)
	dbus? ( sys-apps/dbus )"
DEPEND="${RDEPEND}"

src_prepare() {
	if use cups; then
		CUPS_SERVERBIN="$(cups-config --serverbin)"
	else
		CUPS_SERVERBIN=""
	fi

	# Search for libs in ${libdir}, not just /usr/lib
	epatch "${FILESDIR}"/${PN}-4.0.9-multilib.patch
	eautoreconf

	export CUPS_BACKENDS=${CUPS_SERVERBIN}/backend \
		CUPS_FILTERS=${CUPS_SERVERBIN}/filter CUPS=${CUPS_SERVERBIN}/
}

src_configure() {
	econf $(use_enable dbus)
}

src_install() {
	default

	dosym /usr/bin/foomatic-rip /usr/bin/lpdomatic

	if use cups; then
		dosym /usr/bin/foomatic-gswrapper "${CUPS_SERVERBIN}/filter/foomatic-gswrapper"
		dosym /usr/bin/foomatic-rip "${CUPS_SERVERBIN}/filter/cupsomatic"
	else
		rm -r "${ED}"/${CUPS_SERVERBIN}/filter
		rm -r "${ED}"/${CUPS_SERVERBIN}/backend
	fi
}
