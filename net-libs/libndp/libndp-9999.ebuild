# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit autotools git-r3

DESCRIPTION="Library for Neighbor Discovery Protocol"
HOMEPAGE="https://github.com/jpirko/libndp"
EGIT_REPO_URI="https://github.com/jpirko/${PN}.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}"

src_prepare() {
	eautoreconf
}
