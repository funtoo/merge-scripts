# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/tornado/tornado-2.0.ebuild,v 1.1 2011/06/28 10:37:50 djc Exp $

EAPI="3"
PYTHON_DEPEND="2 3"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="*-jython"

inherit distutils

DESCRIPTION="Scalable, non-blocking web server and tools"
HOMEPAGE="http://www.tornadoweb.org/ http://pypi.python.org/pypi/tornado"
SRC_URI="http://github.com/downloads/facebook/tornado/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="dev-python/pycurl
	|| ( dev-lang/python:2.7 dev-lang/python:2.6 dev-python/simplejson )"
DEPEND="${RDEPEND}
	dev-python/setuptools"

src_test() {
	testing() {
		PYTHONPATH="." "$(PYTHON)" tornado/test/runtests.py
	}
	python_execute_function testing
}
