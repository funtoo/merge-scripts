# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit autotools

DESCRIPTION="Library for Neighbor Discovery Protocol"
HOMEPAGE="http://libndp.org"
SRC_URI="http://libndp.org/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}"

src_prepare() {
	eautoreconf
}
