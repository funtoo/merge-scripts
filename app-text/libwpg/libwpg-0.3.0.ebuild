# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit alternatives eutils

DESCRIPTION="C++ library to read and parse graphics in WPG"
HOMEPAGE="http://libwpg.sourceforge.net/libwpg.htm"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.xz"

LICENSE="|| ( LGPL-2.1 MPL-2.0 )"
SLOT="0.2"
KEYWORDS="~*"
IUSE="doc static-libs"

RDEPEND="app-text/libwpd:0.9[tools]
	dev-libs/librevenge"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( app-doc/doxygen )"
RDEPEND="${RDEPEND}
	!<app-text/libwpd-0.1.3-r1"

RESTRICT="mirror"

src_configure() {
	econf \
		--disable-werror \
		--program-suffix=-${SLOT} \
		--docdir="${EPREFIX%/}/usr/share/doc/${PF}" \
		$(use_with doc docs) \
		$(use_enable static-libs static)
}

src_install() {
	default
	prune_libtool_files --all
}

pkg_postinst() {
	alternatives_auto_makesym /usr/bin/wpg2svgbatch.pl "/usr/bin/wpg2svgbatch.pl-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2svg "/usr/bin/wpg2svg-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2raw "/usr/bin/wpg2raw-[0-9].[0-9]"	fi
}

pkg_postrm() {
	alternatives_auto_makesym /usr/bin/wpg2svgbatch.pl "/usr/bin/wpg2svgbatch.pl-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2svg "/usr/bin/wpg2svg-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2raw "/usr/bin/wpg2raw-[0-9].[0-9]"
}
