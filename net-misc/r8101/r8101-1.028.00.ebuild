# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit linux-mod eutils

DESCRIPTION="r8101 driver for Realtek 8101E/8102E PCI-E NICs"
HOMEPAGE="http://www.realtek.com.tw"
SRC_URI="http://12244.wpc.azureedge.net/8012244/drivers/rtdrivers/cn/nic/0003-r8101-${PV}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
IUSE=""

KEYWORDS="amd64 x86"

MODULE_NAMES="r8101(net:${S}/src)"
BUILD_TARGETS="modules"

pkg_setup() {
	linux-mod_pkg_setup
	BUILD_PARAMS="KERNELDIR=${KV_DIR}"
}

src_install() {
	linux-mod_src_install
	mv readme README
	dodoc README
}

pkg_postinst() {
	ewarn "r8101 module conflicts with kernel's shipped"
	ewarn "drivers, such as r8169, make sure they are"
	ewarn "blacklisted, see 'man modprobe.d' for a further steps"
}
