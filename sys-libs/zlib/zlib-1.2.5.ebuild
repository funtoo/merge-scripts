# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/zlib/zlib-1.2.5.ebuild,v 1.2 2010/04/20 20:34:54 vapier Exp $

inherit eutils toolchain-funcs

DESCRIPTION="Standard (de)compression library"
HOMEPAGE="http://www.zlib.net/"
SRC_URI="http://www.gzip.org/zlib/${P}.tar.bz2
	http://www.zlib.net/${P}.tar.bz2"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="!<dev-libs/libxml2-2.7.7" #309623

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-1.2.3-mingw-implib.patch #288212
	# trust exit status of the compiler rather than stderr #55434
	# -if test "`(...) 2>&1`" = ""; then
	# +if (...) 2>/dev/null; then
	sed -i 's|\<test "`\([^"]*\) 2>&1`" = ""|\1 2>/dev/null|' configure || die
}

src_compile() {
	case ${CHOST} in
	*-mingw*|mingw*)
		emake -f win32/Makefile.gcc prefix=/usr STRIP= PREFIX=${CHOST}- || die
		;;
	*)	# not an autoconf script, so cant use econf
		./configure --shared --prefix=/usr --libdir=/usr/$(get_libdir) || die
		emake || die
		;;
	esac
}

src_install() {
	emake install DESTDIR="${D}" LDCONFIG=: || die
	dodoc FAQ README ChangeLog doc/*.txt

	case ${CHOST} in
	*-mingw*|mingw*)
		dobin zlib1.dll || die
		dolib libz.dll.a || die
		;;
	*) gen_usr_ldscript -a z ;;
	esac
}
