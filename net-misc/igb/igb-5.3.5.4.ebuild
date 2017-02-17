# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit linux-mod multilib toolchain-funcs

DESCRIPTION="IGB kernel module driver"
HOMEPAGE="http://www.intel.com/support/network/adapter/pro100/sb/CS-032498.htm"
SRC_URI="mirror://sourceforge/project/e1000/igb%20stable/${PV}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
BUILD_TARGETS="clean install"

MODULE_NAMES="igb(drivers/net:${S}/src)"

src_compile() {

CONFIG_CHECK="!CONFIG_IGB"
	cd "${S}/src"
	emake -j1
}

src_install() {
	linux-mod_src_install
	doman igb.7
}


