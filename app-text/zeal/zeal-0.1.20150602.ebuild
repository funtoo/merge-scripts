# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit qmake-utils

DESCRIPTION="Zeal is a simple documentation browser inspired by Dash"
HOMEPAGE="http://zealdocs.org/"
SRC_URI="mirror://funtoo/${P}.tar.bz2"
S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~*"

RDEPEND=">=dev-libs/libappindicator-12.10
>=x11-libs/xcb-util-keysyms-0.3.9
dev-qt/qtcore:5
dev-qt/qtgui:5
dev-qt/qtscript:5
dev-qt/qtwidgets:5
dev-qt/qtsql:5
dev-qt/qtwebkit:5
dev-qt/qtx11extras:5
dev-qt/qtconcurrent:5
dev-qt/qtxml:5"

DEPEND="${RDEPEND} app-arch/libarchive"

src_configure() {
	eqmake5 zeal.pro
}

src_install() {
	emake INSTALL_ROOT="${D}" install
}
