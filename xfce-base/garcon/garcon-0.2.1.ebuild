# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit xfconf

DESCRIPTION="Xfce's freedesktop.org specification compatible menu implementation library"
HOMEPAGE="http://www.xfce.org/projects/libraries/"
SRC_URI="mirror://xfce/src/libs/${PN}/${PV%.*}/${P}.tar.bz2"

LICENSE="LGPL-2 FDL-1.1"
SLOT="0"
KEYWORDS="*"
IUSE="debug"

RDEPEND=">=dev-libs/glib-2.14
	>=xfce-base/libxfce4util-4.10.1"
DEPEND="${RDEPEND}
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig"

pkg_setup() {
	XFCONF=(
		$(xfconf_use_debug)
		--with-html-dir="${EPREFIX}"/usr/share/doc/${PF}/html
		)

	DOCS=( AUTHORS ChangeLog HACKING NEWS README STATUS TODO )
}
