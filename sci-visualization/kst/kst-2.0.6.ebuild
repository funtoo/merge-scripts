# Distributed under the terms of the GNU General Public License v2

EAPI=5

CMAKE_USE_DIR=${S}/cmake

inherit cmake-utils multilib

DESCRIPTION="Fast real-time large-dataset viewing and plotting tool for KDE4"
HOMEPAGE="http://kst.kde.org/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2 LGPL-2 FDL-1.2"
SLOT="0"
KEYWORDS="~*"
IUSE="debug test"
RESTRICT="test"

RDEPEND="
	sci-libs/cfitsio
	sci-libs/getdata
	sci-libs/gsl
	sci-libs/netcdf[cxx]
	dev-qt/qtcore:4
	|| ( ( >=dev-qt/qtgui-4.8.5:4 dev-qt/designer:4 ) <dev-qt/qtgui-4.8.5:4 )
	dev-qt/qtopengl:4
	dev-qt/qtsvg:4
"
DEPEND="${RDEPEND}
	test? ( dev-qt/qttest:4 )
"

DOCS=( AUTHORS ChangeLog )
PATCHES=( "${FILESDIR}/${PN}-2.0.4-cfitsio-includes.patch" )

src_prepare() {
	cmake-utils_src_prepare

	# fix desktop file
	sed -i -e 's/^Categories=/&Education;/' \
		-e '/^Encoding=/d' \
		src/kst/kst2.desktop || die
}

src_configure() {
	local mycmakeargs=(
		-Dkst_install_libdir=$(get_libdir)
		-Dkst_pch=OFF
		-Dkst_release=$(use debug && echo OFF || echo ON)
		-Dkst_rpath=OFF
		-Dkst_svnversion=OFF
		$(cmake-utils_use test kst_test)
	)
	cmake-utils_src_configure
}
