# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit distutils subversion

ESVN_REPO_URI="http://kanola.googlecode.com/svn/trunk/"

DESCRIPTION="A lightweight client for MPD, in PyQt 4"
HOMEPAGE="http://dadexter.googlepages.com/kanola"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""

RDEPEND=">=virtual/python-2.4
	dev-python/PyQt4
	!media-sound/kanola
	kde-base/pykde"

src_compile() {
	distutils_src_compile
}

src_install() {
	distutils_src_install
}

pkg_postinst() {
	python_version
	python_mod_optimize /usr/lib/python${PYVER}/site-packages
}

pkg_postrm() {
	python_version
	python_mod_cleanup
}
