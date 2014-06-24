# Distributed under the terms of the GNU General Public License v2

EAPI=5

EGIT_REPO_URI="git://git.kernel.org/pub/scm/linux/kernel/git/dwmw2/linux-firmware.git"
inherit multilib git-2

DESCRIPTION="Firmware for Atheros ar9170-based WiFi USB adapters (ar9170usb module)"
HOMEPAGE="http://wireless.kernel.org/en/users/Drivers/ar9170#open_firmware"
SRC_URI=""

LICENSE="atheros-firmware"
SLOT="0"
KEYWORDS="~*"
IUSE=""

DEPEND=""
RDEPEND="|| ( virtual/udev
		sys-apps/hotplug )"

S="${WORKDIR}/${MY_P}"

src_install() {
	insinto /$(get_libdir)/firmware
	doins ar9170-{1,2}.fw

	dodoc "LICENCE.atheros_firmware"
}
