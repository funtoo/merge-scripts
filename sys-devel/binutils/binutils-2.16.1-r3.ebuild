# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/binutils/binutils-2.16.1-r3.ebuild,v 1.7 2006/09/16 21:53:51 vapier Exp $

PATCHVER="1.11"
UCLIBC_PATCHVER="1.1"
ELF2FLT_VER=""
inherit toolchain-binutils

# ARCH - packages to test before marking
KEYWORDS="-* alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"

src_unpack() {
	tc-binutils_unpack

	cd "${WORKDIR}"/patch
	# playstation2 patches are not safe for other mips targets
	mv *playstation2* skip/

	tc-binutils_apply_patches
}
