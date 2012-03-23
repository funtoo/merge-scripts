# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_RESTRICTED_ABIS="2.[45] 3.* *-jython *-pypy-*"
PYTHON_MULTIPLE_ABIS=1

inherit distutils

DESCRIPTION="Nova is a cloud computing fabric controller (the main part of an IaaS system). It is written in Python."
HOMEPAGE="https://launchpad.net/nova"
SRC_URI="http://launchpad.net/${PN}/diablo/${PV}/+download/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools dev-python/lockfile dev-python/netaddr dev-python/eventlet dev-python/python-gflags dev-python/nosexcover dev-python/sqlalchemy-migrate dev-python/pylint dev-python/mox dev-python/pep8 dev-python/cheetah dev-python/carrot dev-python/lxml dev-python/python-daemon dev-python/wsgiref dev-python/sphinx dev-python/suds dev-python/paramiko dev-python/feedparser)"
RDEPEND="${DEPEND}
		 $(python_abi_depend dev-python/m2crypto dev-python/python-novaclient dev-python/nova-adminclient dev-python/boto )
		 sys-cluster/glance"



