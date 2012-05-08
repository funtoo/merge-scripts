# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS="1"

inherit git-2 distutils

DESCRIPTION="This is a client for the OpenStack Nova API. There's a Python API
(the novaclient module), and a command-line script (nova). Each implements 100%
of the OpenStack Nova API."
HOMEPAGE="https://github.com/rackspace/python-novaclient"
if [ "$PV" = "9999" ]; then
	EGIT_REPO_URI="https://github.com/openstack/python-novaclient"
else
	SRC_URI="http://c.pypi.python.org/packages/source/${PN:0:1}/${PN}/${P}.tar.gz"
fi

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND="${DEPEND}"

