# Distributed under the terms of the GNU General Public License v2

EAPI="2"

DESCRIPTION="a pipeline manipulation library"
HOMEPAGE="http://libpipeline.nongnu.org/"
SRC_URI="mirror://nongnu/${PN}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="static-libs test"

RDEPEND=""
DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? ( dev-libs/check )"

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc ChangeLog NEWS README TODO

	use static-libs || find "${D}" -name '*.la' -exec rm -f '{}' +
}
