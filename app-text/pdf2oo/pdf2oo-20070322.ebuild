# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="1"

DESCRIPTION="Converts pdf files to odf"
HOMEPAGE="http://sourceforge.net/projects/pdf2oo/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE="kde"

# will not work with KDE4, uses DCOP
DEPEND=""
RDEPEND=">=app-text/poppler-0.5.3
	>=media-gfx/imagemagick-6.2.8.0
	>=app-arch/zip-2.31
	kde? ( || ( ( >=kde-base/kdialog-3.5.0:3.5 >=kde-base/kommander-3.5.2:3.5 ) kde-base/kdebase:3.5 )
		>=kde-base/kdelibs-3.5.2-r6:3.5 )"

S="${WORKDIR}/${PN}"

src_install() {
	dobin pdf2oo
	dodoc README
}
