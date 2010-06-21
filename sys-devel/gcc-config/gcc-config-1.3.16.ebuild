# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc-config/gcc-config-1.3.16.ebuild,v 1.10 2007/06/02 11:43:58 armin76 Exp $

inherit flag-o-matic toolchain-funcs multilib

# Version of .c wrapper to use
W_VER="1.4.8"

DESCRIPTION="Utility to change the gcc compiler being used"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE=""

RDEPEND="!app-admin/eselect-compiler sys-apps/openrc"

S=${WORKDIR}

src_compile() {
	strip-flags
	$(tc-getCC) ${CFLAGS} ${LDFLAGS} -Wall -o wrapper \
		"${FILESDIR}"/wrapper-${W_VER}.c || die "compile wrapper"
}

src_install() {
	newbin "${FILESDIR}"/${PN}-${PV} ${PN} || die "install gcc-config"
	sed -i \
		-e "s:PORTAGE-VERSION:${PVR}:g" \
		-e "s:GENTOO_LIBDIR:$(get_libdir):g" \
		"${D}"/usr/bin/${PN}

	exeinto /usr/$(get_libdir)/misc
	newexe wrapper gcc-config || die "install wrapper"
}

pkg_postinst() {
	# Do we have a valid multi ver setup ?
	if gcc-config --get-current-profile &>/dev/null ; then
		# We not longer use the /usr/include/g++-v3 hacks, as
		# it is not needed ...
		[[ -L ${ROOT}/usr/include/g++ ]] && rm -f "${ROOT}"/usr/include/g++
		[[ -L ${ROOT}/usr/include/g++-v3 ]] && rm -f "${ROOT}"/usr/include/g++-v3
		gcc-config $(/usr/bin/gcc-config --get-current-profile)
	fi

	# Make sure old versions dont exist #79062
	rm -f "${ROOT}"/usr/sbin/gcc-config
}
