# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit multilib-build

DESCRIPTION="Virtual for libusb"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="1"
KEYWORDS="*"
IUSE=""

RDEPEND="|| ( >=dev-libs/libusb-1.0.9-r2:1[${MULTILIB_USEDEP}] >=sys-freebsd/freebsd-lib-9.1_rc3-r1[usb,${MULTILIB_USEDEP}] )"
DEPEND=""
