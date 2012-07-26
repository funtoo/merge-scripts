# Distributed under the terms of the GNU General Public License v2

EAPI="4"

DESCRIPTION="Hardware (PCI, USB) IDs databases"
HOMEPAGE="https://github.com/gentoo/hwids"
SRC_URI="https://github.com/gentoo/hwids/tarball/${P} -> ${P}.tar.gz"

LICENSE="|| ( GPL-2 BSD )"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="!<sys-apps/pciutils-3.1.9-r2
	!<sys-apps/usbutils-005-r1"

S="${WORKDIR}"

src_compile() {
	cd "${S}"/gentoo-hwids-*

	for file in {usb,pci}.ids; do
		gzip -c ${file} > ${file}.gz || die
	done
}

src_install() {
	cd "${S}"/gentoo-hwids-*

	insinto /usr/share/misc
	doins {usb,pci}.ids{,.gz}

	dodoc README.md
}
