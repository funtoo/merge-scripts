# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils

DESCRIPTION="Program and text file generation"
HOMEPAGE="http://www.gnu.org/software/autogen/"
SRC_URI="mirror://gnu/${PN}/rel${PV}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=">=dev-scheme/guile-1.8:=
	dev-libs/libxml2"
DEPEND="${RDEPEND}"

src_install() {
	default
	dodoc NOTES TODO
	rm "${ED}"/usr/share/autogen/libopts-*.tar.gz || die
}
