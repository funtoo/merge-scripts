# Distributed under the terms of the GNU General Public License v2

EAPI=5

AUTOTOOLS_AUTORECONF=yes

inherit autotools-utils multilib

GSHHG="gshhg-gmt-2.3.4"

DESCRIPTION="Powerful map generator"
HOMEPAGE="http://gmt.soest.hawaii.edu/"
SRC_URI="ftp://ftp.soest.hawaii.edu/gmt/${P}-src.tar.bz2 ftp://ftp.soest.hawaii.edu/gmt/${GSHHG}.tar.gz
	gmttria? ( ftp://ftp.soest.hawaii.edu/gmt/${P}-non-gpl-src.tar.bz2 )"

LICENSE="GPL-2 gmttria? ( Artistic )"
SLOT="0"
KEYWORDS="*"
IUSE="debug +gdal gmttria metric +mex +netcdf +octave postscript"

RDEPEND="
	!sci-biology/probcons
	gdal? ( sci-libs/gdal )
	netcdf? ( >=sci-libs/netcdf-4.1 )
	octave? ( sci-mathematics/octave )
	postscript? ( app-text/ghostscript-gpl )
"
DEPEND="${RDEPEND}"

# hand written make files that are not parallel safe
MAKEOPTS+=" -j1"

PATCHES=(
	"${FILESDIR}"/${PN}-4.5.9-no-strip.patch
	"${FILESDIR}"/${PN}-4.5.6-respect-ldflags.patch
	)

AUTOTOOLS_IN_SOURCE_BUILD=1

src_prepare() {
	tc-export AR RANLIB
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--libdir=/usr/$(get_libdir)/${P}
		--includedir=/usr/include/${P}
		--datadir=/usr/share/${P}
		--docdir=/usr/share/doc/${PF}
		--disable-update
		--disable-xgrid
		--disable-debug
		--enable-shared
		--enable-flock
		$(use_enable gdal)
		$(use_enable metric US)
		$(use_enable mex)
		$(use_enable netcdf)
		$(use_enable octave)
		$(use_enable debug devdebug)
		$(use_enable postscript eps)
		$(use_enable gmttria triangle)
		)
	autotools-utils_src_configure
}

src_install() {
	autotools-utils_src_install install-all

	# remove static libs
	find "${ED}/usr/$(get_libdir)" -name '*.a' -exec rm -f {} +

	cat <<- _EOF_ > "${T}/99gmt"
	GMTHOME="${EPREFIX}/usr/share/${P}"
	GMT_SHAREDIR="${EPREFIX}/usr/share/${P}"
	_EOF_
	doenvd "${T}/99gmt"
}
