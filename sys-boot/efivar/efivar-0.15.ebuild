# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit

DESCRIPTION="Tools and library to manipulate EFI variables"
HOMEPAGE="https://github.com/vathpela/efivar"
SRC_URI="https://github.com/vathpela/${PN}/archive/${PV}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~*"
IUSE=""

RESTRICT="mirror"

DEPEND="dev-libs/popt"
RDEPEND="${DEPEND}"

src_compile() {
	OPT_FLAGS="${CFLAGS}"
	unset CFLAGS
	emake \
		OPT_FLAGS="${OPT_FLAGS}" \
		libdir=$(get_libdir) \
		|| die "emake failed"
}
