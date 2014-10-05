# Distributed under the terms of the GNU General Public License v2

DESCRIPTION="Manages multiple Jython versions"
HOMEPAGE="http://www.funtoo.org/Package:Eselect_(Jython)"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=">=app-admin/eselect-1.3.5"

src_install() {
	insinto /usr/share/eselect/modules
	newins "${FILESDIR}/jython.eselect-${PVR}" jython.eselect || die
}
