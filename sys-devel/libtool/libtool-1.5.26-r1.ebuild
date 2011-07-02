# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/libtool/libtool-1.5.26-r1.ebuild,v 1.2 2010/09/26 21:23:14 ssuominen Exp $

EAPI="2"

DESCRIPTION="A shared library tool for developers"
HOMEPAGE="http://www.gnu.org/software/libtool/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1.5"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

S=${WORKDIR}/${P}/libltdl

src_configure() {
	econf --disable-static || die
}

src_install() {
	emake DESTDIR="${D}" install-exec || die
	# basically we just install ABI libs for old packages
	rm "${D}"/usr/*/libltdl.{la,so} || die
}
