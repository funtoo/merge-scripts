# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/python-twitter/python-twitter-0.6.ebuild,v 1.6 2009/12/09 18:50:22 nixnut Exp $

EAPI="2"
SUPPORT_PYTHON_ABIS="1"

inherit distutils

DESCRIPTION="This library provides a pure python interface for the Twitter API"
HOMEPAGE="http://code.google.com/p/python-twitter/"
SRC_URI="http://python-twitter.googlecode.com/files/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="examples"

RDEPEND="dev-python/simplejson"
DEPEND="${RDEPEND}
	dev-python/setuptools"
RESTRICT_PYTHON_ABIS="3.*"

DOCS="CHANGES README"
PYTHON_MODNAME="twitter.py"

src_prepare() {
	distutils_src_prepare

	# Delete internal copy of simplejson.
	rm -fr simplejson
}

src_test() {
	testing() {
		PYTHONPATH="build-${PYTHON_ABI}/lib" "$(PYTHON)" twitter_test.py
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	dohtml doc/twitter.html

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*
	fi
}
