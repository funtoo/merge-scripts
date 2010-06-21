# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/gpm/gpm-1.20.5.ebuild,v 1.1 2008/06/19 01:13:40 vapier Exp $

# emacs support disabled due to Bug 99533

inherit eutils toolchain-funcs flag-o-matic

DESCRIPTION="Console-based mouse driver"
HOMEPAGE="http://linux.schottelius.org/gpm/"
SRC_URI="http://linux.schottelius.org/gpm/archives/${P}.tar.lzma"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="selinux"

DEPEND="app-arch/lzma-utils"
RDEPEND="selinux? ( sec-policy/selinux-gpm )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-1.20.5-abi.patch

	# disable ncurses manually since the --disable-curses option doesn't seem to
	# do anything. We don't need to be linking in the curses stuff.

	cat src/Makefile.in | sed -e "s/@CURSES_OBJS@//" > src/Makefile.in.new
	mv src/Makefile.in.new src/Makefile.in

}

src_compile() {
	econf \
		--libdir=/$(get_libdir) \
		--sysconfdir=/etc/gpm \
		|| die "econf failed"

	# workaround broken release
	find -name '*.o' | xargs rm
	emake clean || die
	emake -j1 -C doc || die

	emake EMACS=: || die "emake failed"
}

src_install() {
	emake install DESTDIR="${D}" EMACS=: ELISP="" || die "make install failed"

	dosym libgpm.so.1.20.0 /$(get_libdir)/libgpm.so.1
	dosym libgpm.so.1 /$(get_libdir)/libgpm.so
	dodir /usr/$(get_libdir)
	mv "${D}"/$(get_libdir)/libgpm.a "${D}"/usr/$(get_libdir)/ || die
	gen_usr_ldscript libgpm.so

	insinto /etc/gpm
	doins conf/gpm-*.conf

	dodoc BUGS Changes README TODO
	dodoc doc/Announce doc/FAQ doc/README*

	newinitd "${FILESDIR}"/gpm.rc6 gpm
	newconfd "${FILESDIR}"/gpm.conf.d gpm
}
