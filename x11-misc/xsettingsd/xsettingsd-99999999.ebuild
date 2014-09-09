# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit git-2 scons-utils

DESCRIPTION="A daemon that implements the XSETTINGS specification"
HOMEPAGE="https://code.google.com/p/xsettingsd"
EGIT_REPO_URI="https://github.com/derat/xsettingsd.git"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="x11-libs/libX11"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_compile() {
	escons
}

src_install() {
	dobin xsettingsd dump_xsettings || die
	doman xsettingsd.1 dump_xsettings.1 || die
}
