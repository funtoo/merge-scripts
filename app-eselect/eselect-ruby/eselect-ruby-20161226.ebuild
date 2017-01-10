# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Manages multiple Ruby versions"
HOMEPAGE="https://www.gentoo.org"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=">=app-admin/eselect-1.0.2"

S=${WORKDIR}

src_install() {
	insinto /usr/share/eselect/modules
	newins "${FILESDIR}/ruby.eselect-${PVR}" ruby.eselect || die
}
