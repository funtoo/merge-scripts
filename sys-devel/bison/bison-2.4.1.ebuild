# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: 

inherit toolchain-funcs flag-o-matic

DESCRIPTION="A yacc-compatible parser generator"
HOMEPAGE="http://www.gnu.org/software/bison/bison.html"
SRC_URI="mirror://gnu/bison/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="nls static liby"

# need flex since we patch scan-code.l in ${P}-compat.patch
DEPEND="nls? ( sys-devel/gettext ) sys-devel/flex"
RDEPEND="sys-devel/m4"

src_unpack() {
	unpack ${A}
	cd "${S}"
	# since we patch sources, update mtimes on docs so we dont regen
	touch doc/bison.1 doc/bison.info doc/cross-options.texi
}

src_compile() {
	use static && append-ldflags -static
	econf $(use_enable nls) || die
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
