# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MY_PN="iwlwifi-3945-ucode"

DESCRIPTION="Intel (R) PRO/Wireless 3945ABG Network Connection ucode"
HOMEPAGE="http://linuxwireless.org/en/users/Drivers/iwlegacy"
SRC_URI="http://linuxwireless.org/en/users/Drivers/iwlegacy/${MY_PN}-${PV}.tgz"

LICENSE="ipw3945"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

S="${WORKDIR}/${MY_PN}-${PV}"

src_compile() {
	true;
}

src_install() {
	insinto /lib/firmware
	doins iwlwifi-3945-1.ucode

	dodoc README*
}
