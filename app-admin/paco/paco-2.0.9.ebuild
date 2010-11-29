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
	econf $myconf
}

src_install() {
	make DESTDIR="${D}" install || die
	dodoc BUGS ChangeLog README doc/pacorc doc/faq.txt
	# We want docs in /usr/share/doc/paco.
	rm -fr "${D}/usr/share/paco" || die
}
