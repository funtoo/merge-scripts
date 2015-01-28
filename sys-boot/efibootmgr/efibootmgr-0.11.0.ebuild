# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit

DESCRIPTION="Interact with the EFI Boot Manager"
HOMEPAGE="https://github.com/vathpela/efibootmgr"
SRC_URI="https://github.com/vathpela/${PN}/releases/download/${PN}-${PV}/${PN}-${PV}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RESTRICT="mirror"

RDEPEND="sys-apps/pciutils
	sys-libs/efivar"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_install() {
	# build system uses perl, so just do it ourselves
	dosbin src/efibootmgr/efibootmgr
	doman src/man/man8/efibootmgr.8
	dodoc AUTHORS README doc/ChangeLog doc/TODO
}
