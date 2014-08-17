# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils

DESCRIPTION="Standalone file import filter library for spreadsheet documents"
HOMEPAGE="http://gitorious.org/orcus/pages/Home"
SRC_URI="http://kohei.us/files/orcus/src/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0/0.5"
KEYWORDS="~*"
IUSE="static-libs"

RDEPEND="
	>=dev-libs/boost-1.51.0:=
	>=dev-libs/libixion-0.7:=
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	>=dev-util/mdds-0.8.1:=
"

src_configure() {
	econf \
		--disable-werror \
		$(use_enable static-libs static)
}

src_install() {
	default

	prune_libtool_files --all
}
