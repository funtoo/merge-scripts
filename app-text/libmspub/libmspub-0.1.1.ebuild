# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit base eutils

DESCRIPTION="Library parsing the Microsoft Publisher documents"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/libmspub"
SRC_URI="http://dev-www.libreoffice.org/src/${PN}/${P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~*"
IUSE="doc static-libs"

RDEPEND="
	app-text/libwpd:0.9
	app-text/libwpg:0.2
	dev-libs/icu:=
	dev-libs/librevenge
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	dev-libs/boost
	sys-devel/libtool
	doc? ( app-doc/doxygen )
"

RESTRICT="mirror"

src_prepare() {
	base_src_prepare
	[[ -d m4 ]] || mkdir "m4"
}

src_configure() {
	econf \
		--docdir="${EPREFIX}/usr/share/doc/${PF}" \
		$(use_enable static-libs static) \
		--disable-werror \
		$(use_with doc docs)
}

src_install() {
	default
	prune_libtool_files --all
}
