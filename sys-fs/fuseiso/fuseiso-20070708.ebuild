# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/fuseiso/fuseiso-20070708.ebuild,v 1.3 2010/05/24 19:01:59 pacho Exp $

EAPI=2
inherit eutils

DESCRIPTION="Fuse module to mount ISO9660"
HOMEPAGE="http://fuseiso.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="sys-fs/fuse
	sys-libs/zlib
	dev-libs/glib:2"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${P}-largeiso.patch
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README
}
