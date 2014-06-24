# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit multilib versionator

MY_PN=ar9170
MY_PV=$(replace_all_version_separators '-')

DESCRIPTION="Firmware for Atheros ar9170-based WiFi USB adapters (ar9170usb module)"
HOMEPAGE="http://wireless.kernel.org/en/users/Drivers/ar9170#open_firmware"
SRC_URI="https://api.opensuse.org/public/source/driver:wireless/ar9170-firmware/${MY_PN}.fw"

LICENSE="atheros-firmware"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="|| ( virtual/udev
		sys-apps/hotplug )"

src_install() {
	insinto /$(get_libdir)/firmware
	doins "${DISTDIR}/${MY_PN}.fw"
}
