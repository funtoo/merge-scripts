# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MY_PN="iwlwifi-5000-ucode"
MY_PV="${PV}-1"

DESCRIPTION="Intel (R) Wireless WiFi Link 5100/5300 ucode"
HOMEPAGE="http://linuxwireless.org/en/users/Drivers/iwlwifi/"
SRC_URI="http://linuxwireless.org/attachments/en/users/Drivers/iwlwifi/${MY_PN}-${MY_PV}.tgz"

LICENSE="ipw3945"
SLOT="1"
KEYWORDS="~amd64 ~x86"
IUSE=""

S="${WORKDIR}/${MY_PN}-${PV}"

src_compile() {
	true;
}

src_install() {
	insinto /lib/firmware
	doins "${S}/iwlwifi-5000-5.ucode" || die

	dodoc README* || die "dodoc failed"
}
