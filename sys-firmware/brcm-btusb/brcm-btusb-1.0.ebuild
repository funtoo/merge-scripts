# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Firmware for Broadcom-based Bluetooth USB dongles"
HOMEPAGE="http://plugable.com/2014/06/23/plugable-usb-bluetooth-adapter-solving-hfphsp-profile-issues-on-linux/"

LICENSE="Broadcom"
SLOT="0"
KEYWORDS="*"
S=$WORKDIR

src_install() {
	insinto /lib/firmware/brcm
	doins ${FILESDIR}/BCM20702A1-0a5c-21e8.hcd
	dosym BCM20702A1-0a5c-21e8.hcd /lib/firmware/brcm/BCM20702A0-0a5c-21e8.hcd
	doins ${FILESDIR}/BCM20702A1-13d3-3404.hcd
	dosym BCM20702A1-13d3-3404.hcd /lib/firmware/brcm/BCM20702A0-13d3-3404.hcd
}
