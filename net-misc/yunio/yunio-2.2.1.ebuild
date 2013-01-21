# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Yunio."
HOMEPAGE="http://yunio.com/"
SRC_URI="x86? ( http://www.yunio.com/download/yunio-${PV}-generic-i386.tgz )
	amd64? ( http://www.yunio.com/download/yunio-${PV}-generic-amd64.tgz )"

SLOT=0
LICENSE="Custom:yunio"
KEYWORDS="amd64 x86"

DEPEND=""
RDEPEND="media-libs/fontconfig
	x11-libs/libSM
	x11-libs/libXext
	x11-libs/libXrender
"
src_unpack() {
	unpack ${A}
	mkdir "${WORKDIR}/yunio-${PV}"
	mv "${WORKDIR}"/yunio "${S}"
}

src_install() {
	dobin yunio
}
