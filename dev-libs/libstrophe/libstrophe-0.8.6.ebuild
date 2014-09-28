# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit autotools

SRC_URI="https://github.com/strophe/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

DESCRIPTION="A simple, lightweight C library for writing XMPP clients"
HOMEPAGE="http://strophe.im/${PN}"

LICENSE="MIT GPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="doc xml"

RDEPEND="!xml? ( dev-libs/expat )
	xml? ( dev-libs/libxml2 )
	dev-libs/openssl"

DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

src_prepare() {
	eautoreconf
}

src_configure() {
	# expat workaround
	if use xml ; then
		econf --disable-static \
			$(use_with xml libxml2)
	else
		econf --disable-static
	fi
}

src_compile() {
	emake

	if use doc ; then
		doxygen || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc "LICENSE.txt" "README.markdown" || die
	if use doc ; then
		dohtml -r docs/html/*
	fi
}
