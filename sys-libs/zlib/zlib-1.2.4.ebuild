# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/zlib/zlib-1.2.4.ebuild,v 1.4 2010/04/14 02:23:25 vapier Exp $

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
PDEPEND=">=dev-libs/libxml2-2.7.7"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-1.2.4-build.patch
	epatch "${FILESDIR}"/${PN}-1.2.4-visibility-support.patch #149929
	epatch "${FILESDIR}"/${PN}-1.2.4-LDFLAGS.patch #126718
	epatch "${FILESDIR}"/${PN}-1.2.3-mingw-implib.patch #288212
	epatch "${FILESDIR}"/${PN}-1.2.4-configure-LANG.patch
	# trust exit status of the compiler rather than stderr #55434
	# -if test "`(...) 2>&1`" = ""; then
	# +if (...) 2>/dev/null; then
	sed -i 's|\<test "`\([^"]*\) 2>&1`" = ""|\1 2>/dev/null|' configure || die
	sed -i -e '/ldconfig/d' Makefile* || die
}

src_compile() {
	tc-export AR CC RANLIB RC DLLWRAP
	case ${CHOST} in
	*-mingw*|mingw*)
		emake -f win32/Makefile.gcc prefix=/usr || die
		;;
	*)	# not an autoconf script, so cant use econf
		./configure --shared --prefix=/usr --libdir=/usr/$(get_libdir) || die
		emake || die
		;;
	esac
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc FAQ README ChangeLog doc/*.txt

	case ${CHOST} in
	*-mingw*|mingw*)
		dobin zlib1.dll || die
		dolib libz.dll.a || die
		;;
	*) gen_usr_ldscript -a z ;;
	esac
}
