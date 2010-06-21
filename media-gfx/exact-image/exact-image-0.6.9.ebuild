# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

DESCRIPTION="A fast, modern and generic image processing library"
HOMEPAGE="http://www.exactcode.de/site/open_source/exactimage/"
SRC_URI="http://dl.exactcode.de/oss/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="agg expat jpeg jpeg2k lcms lua openexr php perl python ruby swig tiff truetype X"

RDEPEND="agg? ( x11-libs/agg[truetype] )
	expat? ( dev-libs/expat )
	jpeg2k? ( media-libs/jasper )
	jpeg? ( media-libs/jpeg )
	lcms? ( media-libs/lcms )
	lua? ( dev-lang/lua )
	openexr? ( media-libs/openexr )
	php? ( dev-lang/php )
	perl? ( sys-devel/libperl )
	python? ( dev-lang/python )
	ruby? ( dev-lang/ruby )
	tiff? ( media-libs/tiff )
	truetype? ( >=media-libs/freetype-2 )
	X? (
		x11-libs/libXext
		x11-libs/libXt
		x11-libs/libICE
		x11-libs/libSM
	)"

DEPEND="${RDEPEND}
	swig? ( dev-lang/swig )"

src_configure() {
	# evas support is disabled since evas is not on main tree. You can find it
	# on enlightenment overlay
	# bardecode is disabled since it is protected by custom licence
	# libungif is disabled as it is not supported anymore
	myconf=" --without-libungif --without-evas \
		--without-bardecode --prefix=/usr
		$(use_with jpeg libjpeg)\
		$(use_with lua) \
		$(use_with php) \
		$(use_with ruby) \
		$(use_with python) \
		$(use_with swig) \
		$(use_with agg libagg) \
		$(use_with lcms) \
		$(use_with tiff libtiff) \
		$(use_with truetype freetype) \
		$(use_with expat) \
		$(use_with openexr) \
		$(use_with jpeg2k jasper) \
		$(use_with X x11)"
	#econf fails
	./configure ${myconf} || die "configure failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc README || die "dodoc failed"
}
