# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit python distutils subversion

DESCRIPTION="A text based/ncurses client heavily inspired by ncmpc"
HOMEPAGE="http://www.evadmusic.com"
ESVN_REPO_URI="https://evad.svn.sourceforge.net/svnroot/evad/trunk"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""

DEPEND="dev-lang/python[ncurses]"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}/fix-exec.patch"
}

pkg_postinst() {
	python_version
	python_mod_optimize /usr/lib/python${PYVER}/site-packages
}

pkg_postrm() {
	python_version
	python_mod_cleanup
}
