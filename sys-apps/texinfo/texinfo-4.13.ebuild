# Distributed under the terms of the GNU General Public License v2

inherit flag-o-matic

DESCRIPTION="The GNU info program and utilities"
HOMEPAGE="http://www.gnu.org/software/texinfo/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="nls static"

RDEPEND="!=app-text/tetex-2*
	>=sys-libs/ncurses-5.2-r2
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	|| ( app-arch/xz-utils app-arch/lzma-utils )
	nls? ( sys-devel/gettext )"

src_compile() {
	use static && append-ldflags -static
	econf $(use_enable nls) || die

	# Make cross-compiler safe (#196041)
	if tc-is-cross-compiler; then
		emake -C tools/gnulib/lib || die "emake -C tools/gnulib/lib"
	fi

	emake || die "emake"
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"

	dodoc AUTHORS ChangeLog INTRODUCTION NEWS README TODO
	newdoc info/README README.info
	newdoc makeinfo/README README.makeinfo

	rm -f "${D}"/usr/lib/charset.alias #195148
}
