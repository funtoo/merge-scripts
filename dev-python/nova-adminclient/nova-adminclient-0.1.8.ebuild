# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="3.*"

inherit distutils

DESCRIPTION="This is a python client library for consuming the OpenStack Nova admin API"
HOMEPAGE="https://launchpad.net/nova-adminclient"
SRC_URI="http://pypi.python.org/packages/source/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND="$(python_abi_depend dev-python/boto) ${DEPEND}"

