# Distributed under the terms of the GNU General Public License v2

EAPI=2

DESCRIPTION="Virtual for the pkg-config implementation"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="
	|| ( dev-util/pkgconf[pkg-config]
		>=dev-util/pkgconfig-0.26
		dev-util/pkg-config-lite
		dev-util/pkgconfig-openbsd[pkg-config]
	)"
RDEPEND="${DEPEND}"
