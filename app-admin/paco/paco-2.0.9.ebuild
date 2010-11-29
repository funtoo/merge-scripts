# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils autotools

EAPI=3

DESCRIPTION="Source code package organizer"
HOMEPAGE="http://paco.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="gtk +tools"

DEPEND="gtk? ( =dev-cpp/gtkmm-2* )
		dev-util/pkgconfig"

RDEPEND="${DEPEND}"

src_prepare() {
	# Just in case.
	eautoreconf
}

src_configure() {
	if ! use gtk; then myconf+=" --disable-gpaco"; fi
	if ! use tools; then myconf+=" --disable-scripts"; fi
	myconf+=" -with-paco-logdir=/var/lib/paco"
	econf $myconf
}

src_install() {
	make DESTDIR="${D}" install || die
	dodoc BUGS ChangeLog README doc/pacorc doc/faq.txt
	# We want docs in /usr/share/doc/paco.
	rm -fr "${D}/usr/share/paco" || die
}

pkg_postinst() {
	ewarn
	ewarn "Funtoo's Paco use /var/lib/paco instead of /var/log/paco."
	ewarn "If it is upgrade, remember to move your current log to new location."
	ewarn
}
