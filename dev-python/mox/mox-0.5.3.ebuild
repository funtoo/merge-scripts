# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.*"

inherit distutils

DESCRIPTION="A mock object framework for Python, loosely based on EasyMock for Java"
HOMEPAGE="http://code.google.com/p/pymox/"
SRC_URI="http://pymox.googlecode.com/files/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

PYTHON_MODNAME="mox.py stubout.py"

src_test() {
	testing() {
		$(PYTHON) mox_test.py || die
	}

	python_execute_function testing
}
