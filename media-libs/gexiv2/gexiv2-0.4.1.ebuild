# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit versionator multilib toolchain-funcs

MY_PV=$(get_version_component_range 1-2)

DESCRIPTION="gexiv2 is a GObject-based wrapper around the Exiv2 library."
HOMEPAGE="http://trac.yorba.org/wiki/gexiv2/"
SRC_URI="http://www.yorba.org/download/${PN}/${MY_PV}/lib${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="*"
IUSE="static-libs"

RDEPEND="
	dev-libs/glib:2
	>=media-gfx/exiv2-0.21"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/lib${P}

src_prepare() {
	tc-export CXX
	sed -e 's:CFLAGS:CXXFLAGS:g' -i Makefile || die
}

src_configure() {
	./configure --prefix=/usr || die
}

src_install() {
	emake DESTDIR="${D}" LIB="$(get_libdir)" install
	dodoc AUTHORS NEWS README THANKS

	use static-libs || find "${D}" \( -name '*.a' -or -name '*.la' \) -delete
}
