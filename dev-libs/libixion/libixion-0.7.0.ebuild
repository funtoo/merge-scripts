# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils

DESCRIPTION="General purpose formula parser & interpreter"
HOMEPAGE="http://gitorious.org/ixion/pages/Home"
[[ ${PV} == 9999 ]] || SRC_URI="http://kohei.us/files/ixion/src/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0/0.7"
KEYWORDS="~*"
IUSE="static-libs"

RDEPEND="dev-libs/boost:="
DEPEND="${RDEPEND}
	>=dev-util/mdds-0.10.1:=
"

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	default

	prune_libtool_files --all
}
