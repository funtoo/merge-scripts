# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"

PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="2.*"

inherit distutils

DESCRIPTION="Port of sgmllib to python-3 (already part of python-2) - python2 versions will not install any files"
HOMEPAGE="http://feedparser.googlecode.com"
SRC_URI="http://feedparser.googlecode.com/files/feedparser-5.0.tar.gz"

LICENSE="PSF-2.4"
SLOT="0"
KEYWORDS="*"
IUSE=""

S=$WORKDIR/feedparser-5.0

src_prepare() {
	python_copy_sources
}

src_compile() {
	return
}

src_install() {
	realinst() {
		[ "${PYTHON_ABI%%.*}" != "3" ] && return
		insinto "$(python_get_libdir)"
		newins feedparser/sgmllib3.py sgmllib.py || die "newins fail"
	}
	python_execute_function -s realinst
}
