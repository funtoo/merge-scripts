# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libifp/libifp-1.0.0.2.ebuild,v 1.13 2009/10/07 16:16:51 ssuominen Exp $

EAPI=2

DESCRIPTION="A general-purpose library-driver for iRiver's iFP portable audio players."
HOMEPAGE="http://ifp-driver.sourceforge.net/libifp/"
SRC_URI="mirror://sourceforge/ifp-driver/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ia64 ppc ppc64 x86"
IUSE="doc examples"

RDEPEND=">=dev-libs/libusb-0.1"
DEPEND="${RDEPEND}
	doc? ( >=app-doc/doxygen-1.3.7 )
	sys-apps/sed"

src_prepare() {
	sed -e '/CFLAGS=/s:-g -O2:${CFLAGS}:' \
		-e '/CXXFLAGS=/s:-g -O2:${CXXFLAGS}:' \
		-i configure || die "sed failed"
}

src_configure() {
	# hack to prevent docs from building
	use doc || DOCS="have_doxygen=no"

	eval $DOCS econf \
		--with-libusb \
		--with-libifp \
		--without-kmodule \
		$(use_enable examples)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	# clean /usr/bin after installation
	# by moving examples to examples dir
	if use examples; then
	    insinto /usr/share/${PN}/examples
	    doins "${S}"/examples/simple.c "${S}"/examples/ifpline.c
	    mv "${D}"/usr/bin/{simple,ifpline} "${D}"/usr/share/${PN}/examples
	else
	    rm -f "${D}"/usr/bin/{simple,ifpline}
	fi

	use doc && dodoc README ChangeLog TODO
}

pkg_postinst() {
	elog "Install media-sound/libifp-module for kernel support."
}
