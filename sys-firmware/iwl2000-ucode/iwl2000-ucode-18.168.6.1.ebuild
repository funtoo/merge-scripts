# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MY_PN=${PN/iwl/iwlwifi-}



DESCRIPTION="Intel (R) Centrino (R) Wireless-N 2200 ucode"
HOMEPAGE="http://linuxwireless.org/en/users/Drivers/iwlwifi"
SRC_URI="http://linuxwireless.org/attachments/en/users/Drivers/iwlwifi/iwlwifi-2000-ucode-${PV}.tgz"

LICENSE="ipw3945"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

S="${WORKDIR}/${MY_PN}-${PV}"

src_compile() { :; }

src_install() {
	insinto /lib/firmware
	doins iwlwifi-2000-6.ucode

	dodoc README*
}
