# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libifp/libifp-1.0.0.2.ebuild,v 1.9 2006/07/18 17:34:31 tsunam Exp $

DESCRIPTION="A general-purpose library-driver for iRiver's iFP portable audio players."
HOMEPAGE="http://ifp-driver.sourceforge.net/libifp/"
SRC_URI="mirror://sourceforge/ifp-driver/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ia64 ppc ppc64 x86"
IUSE="doc examples module hal"

DEPEND=">=dev-libs/libusb-0.1.0
	doc? ( >=app-doc/doxygen-1.3.7 )
	hal? ( >=sys-apps/hal-0.5.11 )"

RDEPEND=">=dev-libs/libusb-0.1.0
	module? (
		kernel_linux? ( ~media-sound/libifp-module-${PV} )
	)"

src_compile() {
	# hack to prevent docs from building
	use doc || DOCS="have_doxygen=no"

	eval $DOCS econf \
		--with-libusb \
		--with-libifp \
		--without-kmodule \
		$(use_enable examples) \
		|| die "configure failed"

	emake || die "emake failed"
}

src_install() {
	make install DESTDIR="${D}" || die "make install failed"

	# clean /usr/bin after installation
	# by moving examples to examples dir
	if use examples; then
	    insinto /usr/share/${PN}/examples
	    doins ${S}/examples/simple.c ${S}/examples/ifpline.c
	    mv ${D}/usr/bin/{simple,ifpline} ${D}/usr/share/${PN}/examples
	else
	    rm -f ${D}/usr/bin/{simple,ifpline}
	fi

	if use hal; then
	    insinto /usr/share/hal/fdi/information/20thirdparty
		newins ${FILESDIR}/libifp.fdi 10-libifp.fdi
	fi

	use doc && dodoc README ChangeLog TODO
}
