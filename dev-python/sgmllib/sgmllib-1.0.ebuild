# Copyright 2011 Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI="2"

PYTHON_DEPEND="*"
SUPPORT_PYTHON_ABIS="1"

inherit distutils

DESCRIPTION="Port of sgmllib to python-3 (already part of python-2) - python2 versions will not install any files"
HOMEPAGE="http://feedparser.googlecode.com"
SRC_URI="http://feedparser.googlecode.com/files/feedparser-5.0.tar.gz"

LICENSE="PSF-2.4"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~x86-solaris"
IUSE=""

DEPEND=""
RDEPEND=""

S=$WORKDIR/feedparser-5.0


src_prepare() {
	python_copy_sources
}

src_compile() {
	return
}

src_install() {
	realinst() {
		[ "${PYTHON_ABI}" != "3.*" ] && return
		insinto "$(python_get_libdir)"
		newins feedparser/sgmllib3.py sgmllib.py || die "newins fail"
	}
	python_execute_function -s realinst
}
