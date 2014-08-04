# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit autotools

DESCRIPTION="Library for Neighbor Discovery Protocol"
HOMEPAGE="https://github.com/jpirko/libndp"
SRC_URI="https://github.com/jpirko/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="*"
IUSE=""

RESTRICT="mirror"

RDEPEND=""
DEPEND="${RDEPEND}"

src_prepare() {
	eautoreconf
}
