# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/mico/mico-2.3.13-r3.ebuild,v 1.3 2010/06/17 20:58:35 patrick Exp $

EAPI="2"

inherit eutils flag-o-matic toolchain-funcs

DESCRIPTION="A freely available and fully compliant implementation of the CORBA standard"
HOMEPAGE="http://www.mico.org/"
SRC_URI="http://www.mico.org/${P}.tar.gz"

LICENSE="GPL-2 LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ppc ~sparc ~x86 ~ppc-aix ~ia64-hpux ~amd64-linux ~x86-linux ~sparc-solaris ~x86-winnt"
IUSE="gtk postgres qt4 ssl tcl threads X"
RESTRICT="test" #298101

# doesn't compile:
#   bluetooth? ( net-wireless/bluez )

RDEPEND="
	gtk?       ( x11-libs/gtk+:2 )
	postgres?  ( dev-db/postgresql-base )
	qt4?       ( x11-libs/qt-gui:4[qt3support] )
	ssl?       ( dev-libs/openssl )
	tcl?       ( dev-lang/tcl )
	X?         ( x11-libs/libXt )
"
DEPEND="${RDEPEND}
	>=sys-devel/flex-2.5.2
	>=sys-devel/bison-1.22
"

S=${WORKDIR}/${PN}

src_prepare() {
	epatch "${FILESDIR}"/${P}-nolibcheck.patch
	epatch "${FILESDIR}"/${P}-gcc43.patch
	epatch "${FILESDIR}"/${P}-pthread.patch
	epatch "${FILESDIR}"/${P}-aix.patch
	epatch "${FILESDIR}"/${P}-hpux.patch
	epatch "${FILESDIR}"/${P}-as-needed.patch #280678
	epatch "${FILESDIR}"/${P}-qt4-nothread.patch
	epatch "${FILESDIR}"/${P}-drop-pgsql-header-check.patch

	[[ ${CHOST} == *-winnt* ]] && epatch "${FILESDIR}"/${P}-winnt.patch.bz2

	# cannot use big TOC (AIX only), gdb doesn't like it.
	# This assumes that the compiler (or -wrapper) uses
	# gcc flag '-mminimal-toc' for compilation.
	sed -i -e 's/,-bbigtoc//' "${S}"/configure

	if use qt4; then
		sed -i -e "s, -lqt\", $(pkg-config --libs Qt3Support)\"," configure ||
			die "cannot update to use Qt3Support of qt4"
	fi
}

src_configure() {
	tc-export CC CXX

	if use gtk; then
		# set up gtk-1 wrapper for gtk-2
		mkdir "${T}"/path || die "failed to create temporary path"
		cp "${FILESDIR}"/gtk-config "${T}"/path || die "failed to dupe gtk-config"
		chmod +x "${T}"/path/gtk-config || die "failed to arm gtk-config"
		export PATH="${T}"/path:${PATH}
	fi

	# Don't know which version of JavaCUP would suffice, but there is no
	# configure argument to disable checking for JavaCUP.
	# So we override the configure check to not find 'javac'.
	export ac_cv_path_JAVAC=no

	# '--without-ssl' just does not add another search path - the only way
	# to disable openssl utilization seems to override the configure check.
	use ssl || export ac_cv_lib_ssl_open=no

	# CFLAGS aren't used when checking for <qapplication.h>, but CPPFLAGS are.
	use qt4 && append-cppflags $(pkg-config --cflags Qt3Support)

	local winopts=
	if [[ ${CHOST} == *-winnt* ]]; then
		# disabling static libs, since ar on interix takes nearly
		# one hour per library, thanks to mico's monster objects.
		winopts="${winopts} --disable-threads --disable-static --enable-final"
		append-flags -D__STDC__
	fi

	# http://www.mico.org/pipermail/mico-devel/2009-April/010285.html
	[[ ${CHOST} == *-hpux* ]] && append-cppflags -D_XOPEN_SOURCE_EXTENDED

	# '--without-*' or '--with-*=no' does not disable some features, the value
	# needs to be empty instead. This applies to: bluetooth, gtk, pgsql, qt, tcl.
	# But --without-x works.

	# bluetooth and wireless both don't compile cleanly
	econf \
		--disable-mini-stl \
		$(use_enable threads) \
		--with-gtk=$(use gtk && echo "${EPREFIX}"/usr) \
		--with-pgsql=$(use postgres && echo "${EPREFIX}"/usr) \
		--with-qt=$(use qt4 && echo "${EPREFIX}"/usr) \
		--with-tcl=$(use tcl && echo "${EPREFIX}"/usr) \
		$(use_with X x "${EPREFIX}"/usr) \
		--with-bluetooth='' \
		--disable-wireless \
		${winopts}
}

src_install() {
	emake INSTDIR="${D}${EPREFIX}"/usr SHARED_INSTDIR="${D}${EPREFIX}"/usr install LDCONFIG=: || die "install failed"

	dodir /usr/share || die
	mv "${D}${EPREFIX}"/usr/man "${D}${EPREFIX}"/usr/share || die
	dodir /usr/share/doc/${PF} || die
	mv "${D}${EPREFIX}"/usr/doc "${D}${EPREFIX}"/usr/share/doc/${PF} || die

	dodoc BUGS CHANGES* CONVERT FAQ README* ROADMAP TODO VERSION WTODO || die
}
