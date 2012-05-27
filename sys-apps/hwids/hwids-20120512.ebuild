# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/hwids/hwids-20120512.ebuild,v 1.2 2012/05/16 14:44:10 aballier Exp $

EAPI="4"

DESCRIPTION="Hardware (PCI, USB) IDs databases"
HOMEPAGE="https://github.com/Flameeyes/hwids"
SRC_URI="https://github.com/Flameeyes/hwids/tarball/${P} -> ${P}.tar.gz"

LICENSE="|| ( GPL-2 BSD )"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="!<sys-apps/pciutils-3.1.9-r2
	!<sys-apps/usbutils-005-r1"

S="${WORKDIR}"

src_compile() {
	cd "${S}"/Flameeyes-hwids-*

	for file in {usb,pci}.ids; do
		gzip -c ${file} > ${file}.gz || die
	done
}

src_install() {
	cd "${S}"/Flameeyes-hwids-*

	insinto /usr/share/misc
	doins {usb,pci}.ids{,.gz}

	dodoc README.md
}
