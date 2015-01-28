# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit multilib toolchain-funcs

DESCRIPTION="Tools and library to manipulate EFI variables"
HOMEPAGE="https://github.com/vathpela/efivar"
SRC_URI="https://github.com/vathpela/${PN}/releases/download/${PV}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"

RDEPEND="dev-libs/popt"
DEPEND="${RDEPEND}"

src_configure() {
	tc-export CC
	export libdir="/usr/$(get_libdir)"
}
