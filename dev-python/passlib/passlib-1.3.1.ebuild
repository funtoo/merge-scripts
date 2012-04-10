# Copyright 1999-2012 Gentoo Foundation, Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI=4-python
PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="3.*"

inherit distutils

DESCRIPTION="comprehensive password hashing framework supporting over 20 schemes"
HOMEPAGE="http://code.google.com/p/passlib/"
SRC_URI="http://pypi.python.org/packages/source/p/passlib/${P}.tar.gz"
LICENSE="BSD-2"
KEYWORDS="*"
SLOT="0"
IUSE="test doc"
DEPEND="$(python_abi_depend dev-python/setuptools ) test? ( $(python_abi_depend dev-python/nose ) )"

src_install() {
	distutils_src_install
	if use doc; then
		dodoc "${S}"/docs/*
	fi
}

src_test() {
	PYTHONPATH=. "${python}" setup.py nosetests || die "tests failed"
}

