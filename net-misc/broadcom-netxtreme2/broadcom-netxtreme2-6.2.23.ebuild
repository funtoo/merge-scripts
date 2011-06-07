# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit linux-mod

DESCRIPTION="Broadcom's NetXtremeII (bnx2 and bnx2x) Gigabit and 10GBe drivers"
HOMEPAGE="http://www.broadcom.com/support/ethernet_nic/netxtremeii.php"
SRC_URI="http://www.broadcom.com/docs/driver_download/NXII/linux-${PV}.zip -> broadcom-linux-${PV}.zip"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="app-arch/unzip"
RDEPEND="${DEPEND}"
S="${WORKDIR}/netxtreme2-${PV}"

pkg_setup() {
	BUILD_TARGETS="clean build"
	BUILD_PARAMS="LINUXSRC=${KV_DIR}"
	MODULE_NAMES="
		bnx2(bnx2:kernel/drivers/net:${S}/bnx2)
		bnx2i(bnx2i:kernel/drivers/net:${S}/bnx2i) 
		bnx2x(bnx2x:kernel/drivers/net:${S}/bnx2x)"
}

src_unpack() {
	unpack ${A}
	cd ${WORKDIR}; tar xf ${WORKDIR}/Server/Linux/Driver/netxtreme2-${PV}.tar.gz || die
}
