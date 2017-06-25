# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit linux-info

MY_PN="iwlwifi-5000-ucode"
MY_PV="${PV}-1"

DESCRIPTION="Intel (R) Wireless WiFi Link 5100/5300 ucode"
HOMEPAGE="http://linuxwireless.org/en/users/Drivers/iwlwifi"
SRC_URI="http://linuxwireless.org/attachments/en/users/Drivers/iwlwifi/${MY_PN}-${MY_PV}.tgz"

LICENSE="ipw3945"
SLOT="2"
KEYWORDS="amd64 x86"
IUSE=""
RDEPEND="!=${CATEGORY}/${P}"

S="${WORKDIR}/${MY_PN}-${PV}"

pkg_pretend() {
	if kernel_is lt 2 6 38; then
		ewarn "Your kernel version is ${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}."
		ewarn "This microcode image requires a kernel >= 2.6.38."
		ewarn "For kernel versions < 2.6.38, you may install older SLOTS"
	fi
}

src_install() {
	insinto /lib/firmware
	doins "${S}/iwlwifi-5000-5.ucode"
	dodoc README*
}
