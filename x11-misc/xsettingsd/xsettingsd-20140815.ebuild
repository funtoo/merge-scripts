# Distributed under the terms of the GNU General Public License v2

EAPI="5"

EGIT_REPO_URI="git://github.com/derat/xsettingsd.git"

inherit git-2 scons-utils

DESCRIPTION="A daemon that implements the XSETTINGS specification"
HOMEPAGE="https://code.google.com/p/xsettingsd"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~*"
IUSE=""

RDEPEND="x11-libs/libX11"

DEPEND="${RDEPEND}"

src_compile() {
	escons
}

src_install() {
	dobin xsettingsd dump_xsettings || die
	doman xsettingsd.1 dump_xsettings.1 || die
}
