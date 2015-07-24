# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils kde4-base

DESCRIPTION="KDE digital camera raw image library wrapper"
KEYWORDS="*"
IUSE="debug"

DEPEND="
	>=media-libs/libraw-0.16_beta1-r1:=
"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/libraw-fix.patch
}
