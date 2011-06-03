# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/linux-headers/linux-headers-2.6.38.ebuild,v 1.1 2011/03/18 19:49:01 vapier Exp $

EAPI="3"

ETYPE="headers"
H_SUPPORTEDARCH="alpha amd64 arm bfin cris hppa m68k mips ia64 ppc ppc64 s390 sh sparc x86"
inherit kernel-2
detect_version

PATCH_VER="1"
SRC_URI="mirror://gentoo/gentoo-headers-base-${PV}.tar.xz"
[[ -n ${PATCH_VER} ]] && SRC_URI="${SRC_URI} mirror://gentoo/gentoo-headers-${PV%.1}-${PATCH_VER}.tar.xz"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"

DEPEND="app-arch/xz-utils"
RDEPEND=""

S=${WORKDIR}/gentoo-headers-base-${PV}

src_unpack() {
	unpack ${A}
	cd "${S}"
	[[ -n ${PATCH_VER} ]] && EPATCH_SUFFIX="patch" epatch "${WORKDIR}"/${PV%.1}
}

src_install() {
	kernel-2_src_install
	cd "${D}"
	egrep -r \
		-e '(^|[[:space:](])(asm|volatile|inline)[[:space:](]' \
		-e '\<([us](8|16|32|64))\>' \
		.
	headers___fix $(find -type f)

	egrep -l -r -e '__[us](8|16|32|64)' "${D}" | xargs grep -L linux/types.h

	# hrm, build system sucks
	find "${D}" '(' -name '.install' -o -name '*.cmd' ')' -print0 | xargs -0 rm -f

	# provided by libdrm (for now?)
	rm -rf "${D}"/$(kernel_header_destdir)/drm
}

src_test() {
	emake ARCH=$(tc-arch-kernel) headers_check || die
}
