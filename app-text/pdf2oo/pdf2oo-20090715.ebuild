# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/pdf2oo/pdf2oo-20090715.ebuild,v 1.7 2010/06/15 16:19:24 hwoarang Exp $

EAPI=2

DESCRIPTION="Converts pdf files to odf"
HOMEPAGE="http://sourceforge.net/projects/pdf2oo/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="app-arch/zip
	|| ( media-gfx/imagemagick media-gfx/graphicsmagick[imagemagick] )
	>=app-text/poppler-0.12.3-r3[utils]"

S=${WORKDIR}/${PN}

src_install() {
	dobin pdf2oo || die
	dodoc README || die
}
