# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit linux-info versionator

MY_PN="iwlwifi-7265-ucode"

DV_MAJOR="3"
DV_MINOR="17"
DV_PATCH="0"

DESCRIPTION="Firmware for Intel (R) Dual Band Wireless-AC 7265"
HOMEPAGE="http://wireless.kernel.org/en/users/Drivers/iwlwifi"
SRC_URI="https://wireless.wiki.kernel.org/attachments/en/users/drivers/${MY_PN}-${PV}.tgz"

LICENSE="ipw3945"
SLOT="10"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND=""
RDEPEND="!sys-kernel/linux-firmware[-savedconfig]"

S="${WORKDIR}/${MY_PN}-${PV}"

CONFIG_CHECK="~IWLMVM"
ERROR_IWLMVM="CONFIG_IWLMVM is required to be enabled in /usr/src/linux/.config for the kernel to be able to load the ${DEV_N} firmware"

pkg_pretend() {
	if kernel_is lt "${DV_MAJOR}" "${DV_MINOR}" "${DV_PATCH}"; then
		ewarn "Your kernel version is ${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}."
		ewarn "This microcode image requires a kernel >= ${DV_MAJOR}.${DV_MINOR}.${DV_PATCH}."
		ewarn "For kernel versions < ${DV_MAJOR}.${DV_MINOR}.${DV_PATCH}, you may install older SLOTS"
	fi
}

src_install() {
	insinto /lib/firmware
	doins "${S}/iwlwifi-7265D-${SLOT}.ucode"
	dodoc README*
}
