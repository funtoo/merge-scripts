# Distributed under the terms of the GNU General Public License v2

EAPI=5

XORG_MULTILIB=yes
inherit xorg-2

DESCRIPTION="X.Org GL protocol headers"
KEYWORDS="*"
LICENSE="SGI-B-2.0"
IUSE=""

RDEPEND=">=app-eselect/eselect-opengl-1.3.0"
DEPEND=""

src_install() {
	xorg-2_src_install
}

pkg_postinst() {
	xorg-2_pkg_postinst
	eselect opengl set --ignore-missing --use-old xorg-x11
}
