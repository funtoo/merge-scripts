# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit cmake-utils

DESCRIPTION="Common libraries for the Razor-qt desktop environment"
HOMEPAGE="http://razor-qt.org/"
SRC_URI="http://razor-qt.org/downloads/razorqt-${PV}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1+"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="=razorqt-base/libqtxdg-0.5.2
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXfixes
	x11-libs/libXrender
	dev-qt/qtcore:4
	dev-qt/qtdbus:4
	dev-qt/qtgui:4
	!<razorqt-base/razorqt-meta-0.5.0
	!x11-wm/razorqt"
RDEPEND="${DEPEND}"

S="${WORKDIR}/razorqt-${PV}"

src_configure() {
	local mycmakeargs=(
		-DSPLIT_BUILD=On
		-DMODULE_LIBRAZORQT=On
		-DMODULE_LIBRAZORQXT=On
		-DMODULE_LIBRAZORMOUNT=On
		-DMODULE_ABOUT=On
		-DMODULE_X11INFO=On
	)
	cmake-utils_src_configure
}
