# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2
ESVN_REPO_URI="https://www.schleifi.com/svn/florian/kutempc/"
inherit subversion

DESCRIPTION="KuteMPC is a QT 4.1+ client heavily inspired by glurp"
HOMEPAGE="http://etomite.qballcow.nl/qgmpc-0.12.html"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""

DEPEND=">x11-libs/qt-4.1.0"

src_prepare() {
	qmake
}

src_install() {
	dobin kutempc
	dodoc TODO
}
