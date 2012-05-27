# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/usbutils/usbutils-004.ebuild,v 1.8 2012/05/04 09:17:26 jdhore Exp $

EAPI="3"

PYTHON_DEPEND="python? 2:2.6"

inherit python

DESCRIPTION="USB enumeration utilities"
HOMEPAGE="http://linux-usb.sourceforge.net/"
SRC_URI="mirror://kernel/linux/utils/usb/usbutils/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="network-cron python zlib"

RDEPEND="virtual/libusb:1
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	if use python; then
		python_convert_shebangs 2 lsusb.py
		sed -i -e '/^usbids/s:/usr/share:/usr/share/misc:' lsusb.py || die
	fi
}

src_configure() {
	econf \
		--datarootdir=/usr/share \
		--datadir=/usr/share/misc \
		$(use_enable zlib)
}

src_install() {
	emake DESTDIR="${D}" install || die
	use python || rm -f "${D}"/usr/bin/lsusb.py
	mv "${D}"/usr/sbin/update-usbids{.sh,} || die
	newbin "${FILESDIR}"/usbmodules.sh usbmodules || die
	dodoc AUTHORS ChangeLog NEWS README

	use network-cron || return 0
	exeinto /etc/cron.monthly
	newexe "${FILESDIR}"/usbutils.cron update-usbids || die
}
