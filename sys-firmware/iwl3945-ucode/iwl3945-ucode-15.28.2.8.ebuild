# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MY_P="iwlwifi-3945-ucode-${PV}"

DESCRIPTION="Intel (R) PRO/Wireless 3945ABG Network Connection ucode"
HOMEPAGE="http://linuxwireless.org/en/users/Drivers/iwlegacy/"
SRC_URI="http://linuxwireless.org/en/users/Drivers/iwlegacy/${MY_P}.tgz"

LICENSE="ipw3945"
SLOT="1"
KEYWORDS="~amd64 ~x86"
IUSE=""

S=${WORKDIR}/${MY_P}

src_compile() {
	true;
}

src_install() {
	insinto /lib/firmware
	doins iwlwifi-3945-2.ucode || die
	dodoc README*
}

pkg_postinst() {
	elog
	elog "Due to ucode API change this version of ucode works only with kernels"
	elog ">=2.6.29-rc1. If you have to use older kernels please install ucode"
	elog "with older API:"
	elog "emerge ${CATEGORY}/${PN}:0"
	elog "For more information take a look at bugs.gentoo.org/246045"
	elog
}
