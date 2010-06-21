# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils gnuconfig

DESCRIPTION="Driver for Minolta PagePro 1[234]xxW printers"
HOMEPAGE="http://www.hinterbergen.de/mala/min12xxw/"
SRC_URI="http://www.hinterbergen.de/mala/min12xxw/${P}.tar.gz"

SLOT="0"
IUSE="cups ppds"
LICENSE="GPL-2"
KEYWORDS="~x86 ~ppc ~alpha ~sparc ~hppa ~amd64"

# To be able to print with CUPS, we _need_ the PPD, so let foomatic-filters-ppds
# depend on 'cups' USE flag, not on 'ppds' ... but if set, install PPDS anyway
# http://www.linux-foundation.org/en/OpenPrinting/Database/CUPSDocumentation
DEPEND="cups? ( net-print/cups
		net-print/foomatic-filters-ppds )
	ppds? ( net-print/foomatic-filters-ppds )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	gnuconfig_update
}

src_compile () {
	econf || die "econf failed"
	make || die "make failed"
}

src_install() {
	make DESTDIR="${D}" install || die
}

pkg_postinst() {
	if use cups; then
	    ewarn "WARNING: The driver expects the printer connected at /dev/lp0"
	    ewarn "If you have another naming, CUPS may fail to print."
	fi
	einfo "The driver documentation may be found at LinuxPrinting.org"
	einfo "See http://linuxprinting.org/show_driver.cgi?driver=min12xxw"
}
