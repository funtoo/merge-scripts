# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2

MY_PN="QtMPC"

inherit subversion cmake-utils

DESCRIPTION="Another QT4 client with Amarok-like tree view music library interface."
HOMEPAGE="http://qtmpc.lowblog.nl"
LICENSE="GPL-2"
ESVN_REPO_URI="http://qtmpc.lowblog.nl/svn/trunk"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE="kde"
RDEPEND="x11-libs/qt-gui:4"
#	kde? ( kde-base/kdelibs )"
DEPEND="${RDEPEND}"

#src_configure() {
#	cmake-utils_src_configure $(cmake-utils_use_with kde WANT_KDE_SUPPORT)
#}

src_install() {
	cmake-utils_src_install

	## It appears .svgz doesn't work for some reason
	newicon images/icon.svg "${MY_PN}.svg"

	make_desktop_entry "${MY_PN}" "${MY_PN}" "${MY_PN}"
}
