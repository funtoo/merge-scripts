# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit scons-utils

GITHUB_COMMIT="2a516a91d8352b3b93a7a1ef5606dbd21fa06b7c"

DESCRIPTION="A daemon that implements the XSETTINGS specification"
HOMEPAGE="https://code.google.com/p/xsettingsd"
SRC_URI="https://github.com/derat/xsettingsd/archive/${GITHUB_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~*"
IUSE=""

RDEPEND="x11-libs/libX11"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

S="${WORKDIR}/${PN}-${GITHUB_COMMIT}"

src_compile() {
	escons
}

src_install() {
	dobin xsettingsd dump_xsettings || die
	doman xsettingsd.1 dump_xsettings.1 || die
}
