# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit flag-o-matic

DESCRIPTION="A general-purpose (yacc-compatible) parser generator"
HOMEPAGE="http://www.gnu.org/software/bison/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="nls static"

RDEPEND=">=sys-devel/m4-1.4.16"
DEPEND="${RDEPEND}
	sys-devel/flex
	nls? ( sys-devel/gettext )"

DOCS="AUTHORS ChangeLog-2012 NEWS README THANKS TODO" # ChangeLog-1998 PACKAGING README-alpha README-release

src_configure() {
	use static && append-ldflags -static

	econf \
		--disable-silent-rules \
		$(use_enable nls)
}

src_install() {
	default

	# This one is installed by dev-util/yacc
	mv -v "${ED}"/usr/bin/yacc{,.bison} || die
	mv -v "${ED}"/usr/share/man/man1/yacc{,.bison}.1 || die

	# We do not need liby.a
	rm -r "${ED}"/usr/lib* || die

	# Move to documentation directory and leave compressing for EAPI>=4
	mv -v "${ED}"/usr/share/${PN}/README "${ED}"/usr/share/doc/${PF}/README.data
}

pkg_postinst() {
	local f="${EROOT}/usr/bin/yacc"
	if [[ ! -e ${f} ]] ; then
		ln -s yacc.bison "${f}"
	fi
}

pkg_postrm() {
	# clean up the dead symlink when we get unmerged #377469
	local f="${EROOT}/usr/bin/yacc"
	if [[ -L ${f} && ! -e ${f} ]] ; then
		rm -f "${f}"
	fi
}
