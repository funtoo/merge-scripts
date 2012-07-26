# Distributed under the terms of the GNU General Public License v2

EAPI="2"

DESCRIPTION="A shared library tool for developers"
HOMEPAGE="http://www.gnu.org/software/libtool/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1.5"
KEYWORDS="*"
IUSE=""

S=${WORKDIR}/${P}/libltdl

src_configure() {
	econf --disable-static || die
}

src_install() {
	emake DESTDIR="${D}" install-exec || die
	# basically we just install ABI libs for old packages
	rm "${D}"/usr/*/libltdl.{la,so} || die
}
