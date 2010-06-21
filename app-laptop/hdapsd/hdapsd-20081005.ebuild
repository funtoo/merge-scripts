# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: 

inherit eutils linux-info

PROTECT_VER="3"

DESCRIPTION="IBM ThinkPad Harddrive Active Protection disk head parking daemon"
HOMEPAGE="http://hdaps.sourceforge.net/"
SRC_URI="mirror://gentoo/${P}.c.bz2
	mirror://gentoo/hdaps_protect-patches-${PROTECT_VER}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"

IUSE=""
RDEPEND=""

S="${WORKDIR}"

pkg_setup() {
	# We require the hdaps module which can either come from kernel sources or 
	# from the tp_smapi package.
	if ! has_version app-laptop/tp_smapi || ! built_with_use app-laptop/tp_smapi hdaps; then
		CONFIG_CHECK="SENSORS_HDAPS"
		ERROR_SENSORS_HDAPS="${P} requires app-laptop/tp_smapi (with hdaps USE enabled) or support for CONFIG_SENSORS_HDAPS enabled"
		linux-info_pkg_setup
	fi
}

src_compile() {
	gcc ${CFLAGS} "${P}".c -o hdapsd || die "failed to compile"
}

src_install() {
	dosbin "${WORKDIR}"/hdapsd
	newconfd "${FILESDIR}"/hdapsd.conf hdapsd
	newinitd "${FILESDIR}"/hdapsd.init hdapsd

	# Install udev file
	insinto /etc/udev/rules.d/
	newins "${FILESDIR}"/51-hdaps.rules 51-hdaps.rules
}

pkg_postinst(){
	[[ -z $(ls "${ROOT}"/sys/block/*/queue/protect 2>/dev/null) ]] && \
	[[ -z $(ls "${ROOT}"/sys/block/*/device/unload_heads 2>/dev/null) ]] && \
		ewarn "Your kernel has NOT been patched for blk_freeze!"

	if ! has_version app-laptop/tp_smapi; then
		ewarn "Using the hdaps module provided by app-laptop/tp_smapi instead"
		ewarn "of the in-kernel driver is strongly recommended!"
	fi

	elog "You can change the default frequency by modifing /sys/devices/platform/hdaps/sampling_rate"
}
