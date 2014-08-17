# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils

DESCRIPTION="Library to generate ODF documents from libwpd and libwpg"
HOMEPAGE="http://libwpd.sf.net"
SRC_URI="mirror://sourceforge/libwpd/${P}.tar.xz"

LICENSE="|| ( LGPL-2.1 MPL-2.0 )"
SLOT="0"
KEYWORDS="~*"
IUSE=""

RDEPEND="
	app-text/libetonyek
	app-text/libwpd
	app-text/libwpg
	dev-libs/librevenge
"
DEPEND="${RDEPEND}
	>=dev-libs/boost-1.46
	virtual/pkgconfig
"

RESTRICT="mirror"

src_configure() {
	econf \
		--disable-static \
		--disable-werror \
		--with-sharedptr=boost \
		--docdir="${EPREFIX}"/usr/share/doc/${PF}
}

src_install() {
	default
	prune_libtool_files --all
}
