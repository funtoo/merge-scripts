# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="A free, open source desktop alternative to Microsoft Project."
HOMEPAGE="http://openproj.org/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="CPAL"
SLOT="0"
KEYWORDS="x86"
IUSE=""

DEPEND="|| ( virtual/jre virtual/jdk )"
RDEPEND="${DEPEND}"

src_compile() {
	einfo "Nothing to compile"
}

src_install() {
	rm openproj.bat openproj.sh
	local openprojdir="/usr/share/openproj"

	insinto "${openprojdir}"
	doins -r *

	dobin ${FILESDIR}/${PN}

	dodir /usr/share/applications/
	insinto /usr/share/applications/
	doins ${FILESDIR}/*.desktop

	dodir /usr/share/pixmaps/
	insinto /usr/share/pixmaps/
	doins ${FILESDIR}/${PN}.png
}
