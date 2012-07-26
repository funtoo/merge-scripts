# Distributed under the terms of the GNU General Public License v2

DESCRIPTION="A shared library tool for developers"
HOMEPAGE="http://www.gnu.org/software/libtool/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1.3"
KEYWORDS="*"
IUSE=""

src_compile() {
	econf \
		--enable-ltdl-install \
		--disable-static \
		|| die
	emake -C libltdl || die
}

src_install() {
	emake -C libltdl DESTDIR="${D}" install-exec || die
	# basically we just install ABI libs for old packages
	rm "${D}"/usr/*/libltdl.{la,so} || die
}
