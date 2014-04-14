# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils multilib-minimal

DESCRIPTION="Library to interface with IEEE 1394 cameras following the IIDC specification"
HOMEPAGE="http://sourceforge.net/projects/libdc1394/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="2"
KEYWORDS="~*"
IUSE="doc static-libs X"

RDEPEND=">=sys-libs/libraw1394-1.2.0[${MULTILIB_USEDEP}] virtual/libusb:1[${MULTILIB_USEDEP}] media-libs/libsdl"
DEPEND="${RDEPEND} virtual/pkgconfig
	doc? ( app-doc/doxygen )"

src_prepare() {
	epatch "${FILESDIR}/${P}-includes.patch"
	eautoreconf
}

multilib_src_configure() {
	local myconf="$(use_enable doc doxygen-html)"
	multilib_is_native_abi || myconf="--disable-doxygen-html --disable-examples"

	# X is only useful for examples that are not installed.
	ECONF_SOURCE="${S}" econf \
		$(use_enable static-libs static) \
		--program-suffix=2 \
		--without-x \
		${myconf}
}

multilib_src_compile() {
	default
	multilib_is_native_abi && use doc && emake doc
}

multilib_src_install() {
	default
	multilib_is_native_abi && use doc && dohtml doc/html/*
	find "${ED}" -name '*.la' -exec rm -f {} +
}
