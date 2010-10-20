# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/bison/bison-2.4.2.ebuild,v 1.9 2010/09/12 17:40:52 armin76 Exp $

inherit toolchain-funcs flag-o-matic

DESCRIPTION="A yacc-compatible parser generator"
HOMEPAGE="http://www.gnu.org/software/bison/bison.html"
SRC_URI="mirror://gnu/bison/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="nls static liby"

DEPEND="nls? ( sys-devel/gettext )"
RDEPEND="sys-devel/m4"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-2.4.2-gnulib_spawn.patch # 312697
	epatch "${FILESDIR}"/${PN}-2.4.2-gcc45_testsuite.patch
}

src_compile() {
	use static && append-ldflags -static
	econf $(use_enable nls)
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die

	# This one is installed by dev-util/yacc
	mv "${D}"/usr/bin/yacc{,.bison} || die
	mv "${D}"/usr/share/man/man1/yacc{,.bison}.1 || die

	if ! use liby; then
		rm -r "${D}"/usr/lib* || die
	fi

	dodoc AUTHORS NEWS ChangeLog README OChangeLog THANKS TODO
}

pkg_postinst() {
	if [[ ! -e ${ROOT}/usr/bin/yacc ]] ; then
		ln -s yacc.bison "${ROOT}"/usr/bin/yacc
	fi
}
