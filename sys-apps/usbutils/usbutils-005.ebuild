# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/usbutils/usbutils-005.ebuild,v 1.4 2012/05/04 09:17:26 jdhore Exp $

EAPI="4"

PYTHON_DEPEND="python? 2:2.6"

inherit autotools eutils python

DESCRIPTION="USB enumeration utilities"
HOMEPAGE="http://linux-usb.sourceforge.net/"
SRC_URI="mirror://debian/pool/main/u/${PN}/${PN}_${PV}.orig.tar.gz"
#SRC_URI="mirror://kernel/linux/utils/usb/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
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
	epatch "${FILESDIR}"/${P}-missing-includes.patch

	eautoreconf

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
	default
	newdoc usbhid-dump/NEWS NEWS.usbhid-dump

	# the package (currently) lacks plumbing to use the gzipped file
	rm -f "${ED}"/usr/share/misc/usb.ids.gz

	use python || rm -f "${ED}"/usr/bin/lsusb.py

	mv -vf "${ED}"/usr/sbin/update-usbids{.sh,} || die
	newbin "${FILESDIR}"/usbmodules.sh usbmodules

	use network-cron || return 0
	exeinto /etc/cron.monthly
	newexe "${FILESDIR}"/${PN}.cron update-usbids
}
