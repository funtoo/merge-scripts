# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MY_PN="iwlwifi-4965-ucode"

DESCRIPTION="Intel (R) Wireless WiFi Link 4965AGN ucode"
HOMEPAGE="http://intellinuxwireless.org/?p=iwlwifi"
SRC_URI="http://www.linuxwireless.org/attachments/en/users/Drivers/iwlegacy/${MY_PN}-${PV}.tgz"

LICENSE="ipw3945"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

S="${WORKDIR}/${MY_PN}-${PV}"

src_compile() {
	true;
}

src_install() {
	insinto /lib/firmware
	doins iwlwifi-4965-1.ucode

	dodoc README*
}
