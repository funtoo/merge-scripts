# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"

PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.*"
DISTUTILS_SRC_TEST="nosetests"

inherit distutils

MY_PN="Routes"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="A Python re-implementation of the Rails routes system for mapping URL's to Controllers/Actions."
HOMEPAGE="http://routes.groovie.org http://pypi.python.org/pypi/Routes"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="doc test"

DEPEND="$(python_abi_depend dev-python/setuptools ) test? ( $(python_abi_depend dev-python/coverage ) )"

S="${WORKDIR}/${MY_P}"

src_install() {
	distutils_src_install

	if use doc; then
		cd docs/_build/html
		docinto html
		cp -R [a-z]* _images _static "${ED}usr/share/doc/${PF}/html" || die "Installation of documentation failed"
	fi
}
