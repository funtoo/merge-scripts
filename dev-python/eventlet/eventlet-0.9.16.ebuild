# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy-*"
DISTUTILS_SRC_TEST="nosetests"

inherit distutils

DESCRIPTION="Highly concurrent networking library"
HOMEPAGE="http://pypi.python.org/pypi/eventlet"
SRC_URI="http://pypi.python.org/packages/source/e/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="*"
IUSE="doc examples test"

DEPEND="doc? ( $(python_abi_depend dev-python/sphinx) )
        test? ( $(python_abi_depend dev-python/greenlet) )"
RDEPEND="${DEPEND} $(python_abi_depend dev-python/greenlet)"

src_compile() {
	distutils_src_compile

	if use doc ; then
		emake -C doc html || die
	fi
}

src_install() {
	distutils_src_install

	use doc && dohtml -r doc/_build/html/*

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples || die
	fi
}

