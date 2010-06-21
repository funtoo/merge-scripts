# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-laptop/hdapsd/hdapsd-20090401.ebuild,v 1.2 2009/10/15 02:30:08 mr_bones_ Exp $

EAPI="2"

inherit eutils linux-info toolchain-funcs

DESCRIPTION="IBM ThinkPad Harddrive Active Protection disk head parking daemon"
HOMEPAGE="http://hdaps.sourceforge.net/"
SRC_URI="mirror://sourceforge/hdaps/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"

IUSE=""
RDEPEND=""

pkg_setup() {
	# We require the hdaps module which can either come from kernel sources or
	# from the tp_smapi package.
	if ! has_version app-laptop/tp_smapi || ! built_with_use app-laptop/tp_smapi hdaps; then
		CONFIG_CHECK="~SENSORS_HDAPS"
		ERROR_SENSORS_HDAPS="${P} requires app-laptop/tp_smapi (with hdaps USE enabled) or support for CONFIG_SENSORS_HDAPS enabled"
		linux-info_pkg_setup
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
	rm -rf "${D}"/usr/share/doc/hdapsd
	dodoc ChangeLog README AUTHORS
	newconfd "${FILESDIR}"/hdapsd.conf hdapsd
	newinitd "${FILESDIR}"/hdapsd.init hdapsd
}

pkg_postinst(){
	[[ -z $(ls "${ROOT}"/sys/block/*/queue/protect 2>/dev/null) ]] && \
	[[ -z $(ls "${ROOT}"/sys/block/*/device/unload_heads 2>/dev/null) ]] && \
		ewarn "Your kernel does NOT support shock protection. Kernel 2.6.28 and above is recommended!"

	if ! has_version app-laptop/tp_smapi; then
		ewarn "Using the hdaps module provided by app-laptop/tp_smapi instead"
		ewarn "of the in-kernel driver is strongly recommended!"
	fi

	elog "You can change the default frequency by modifing /sys/devices/platform/hdaps/sampling_rate"
	elog "You might need to enable shock protection manually by running "
	elog "   echo -1 > /sys/block/DEVICE/device/unload_heads"
}
