# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/libtool/libtool-1.3.5.ebuild,v 1.9 2011/02/06 11:36:46 leio Exp ${P}-r1.ebuild,v 1.8 2002/10/04 06:34:42 kloeri Exp $

DESCRIPTION="A shared library tool for developers"
HOMEPAGE="http://www.gnu.org/software/libtool/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1.3"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE=""

src_compile() {
	econf \
		--enable-ltdl-install \
		--disable-static \
		|| die
	emake -C libltdl || die
}

src_install() {
	emake -C libltdl DESTDIR="${D}" install-exec || die
	# basically we just install ABI libs for old packages
	rm "${D}"/usr/*/libltdl.{la,so} || die
}
