# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-laptop/hdapsd/hdapsd-20060409-r1.ebuild,v 1.4 2009/08/31 22:02:20 ikelos Exp $

inherit eutils linux-info

PROTECT_VER="2"

DESCRIPTION="IBM ThinkPad Harddrive Active Protection disk head parking daemon"
HOMEPAGE="http://hdaps.sourceforge.net/"
SRC_URI="mirror://gentoo/${P}.c.bz2
	mirror://gentoo/hdaps_protect-patches-${PROTECT_VER}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"

IUSE=""
RDEPEND=""

S="${WORKDIR}"

CONFIG_CHECK="~SENSORS_HDAPS"
ERROR_SENSORS_HDAPS="${P} requires support for HDAPS (CONFIG_SENSORS_HDAPS)"

src_compile() {
	cd "${WORKDIR}"
	gcc ${CFLAGS} "${P}".c -o hdapsd || die "failed to compile"
}

src_install() {
	dosbin "${WORKDIR}"/hdapsd
	newconfd "${FILESDIR}"/hdapsd.conf hdapsd
	newinitd "${FILESDIR}"/hdapsd.init hdapsd

	# Install our kernel patches
	dodoc *.patch "${FILESDIR}"/hdaps-Z60m.patch
}

# Yes, this sucks as the source location may change, kernel sources may not be
# installed, but we try our best anyway
kernel_patched() {
	get_version

	if grep -qs "blk_protect_register" "${KERNEL_DIR}"/block/ll_rw_blk.c ; then
		einfo "Your kernel has already been patched for blk_freeze"
		return 0
	fi

	return 1
}

pkg_config() {
	kernel_patched && return 0

	local docdir="${ROOT}/usr/share/doc/${PF}/"
	local p="hdaps_protect-${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}.patch.gz"

	# We need to find our FILESDIR as it's now lost
	if [[ ! -e ${docdir}/${p} ]] ; then
		eerror "We don't have a patch for kernel ${KV_MAJOR}.${KV_MINOR}.${KV_PATCH} yet"
		return 1
	fi

	if [[ ! -d ${KERNEL_DIR} ]] ; then
		eerror "Kernel sources not found!"
		return 1
	fi

	cd "${KERNEL_DIR}"
	epatch "${docdir}/${p}"

	# This is just a nice to have for me as I use a Z60m myself
	if ! grep -q "Z60m" "${KERNEL_DIR}"/drivers/hwmon/hdaps.c ; then
		epatch "${docdir}"/hdaps-Z60m.patch.gz
	fi

	echo
	einfo "Now you should rebuild your kernel, its modules"
	einfo "and then install them."
}

pkg_postinst(){
	[[ -n $(ls "${ROOT}"/sys/block/*/queue/protect 2>/dev/null) ]] && return 0

	if ! kernel_patched ; then
		ewarn "Your kernel has NOT been patched for blk_freeze"
		elog "The ebuild can attempt to patch your kernel like so"
		elog "   emerge --config =${PF}"
	fi
}
