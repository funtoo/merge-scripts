# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="2.[45] 3.* *-jython"

inherit distutils

DESCRIPTION="Provides services for discovering, registering, and retrieving
virtual machine images. Glance has a RESTful API that allows querying of VM
image metadata as well as retrieval of the actual image."
HOMEPAGE="https://launchpad.net/glance"
SRC_URI="http://launchpad.net/${PN}/diablo/${PV}/+download/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND="${DEPEND} $(python_abi_depend dev-python/webob dev-python/httplib2 dev-python/routes dev-python/paste dev-python/pastedeploy dev-python/pyxattr dev-python/kombu)"

src_install() {
	distutils_src_install
	newconfd "${FILESDIR}/glance.confd" glance
	newinitd "${FILESDIR}/glance.initd" glance

	for function in api registry scrubber; do
		dosym /etc/init.d/glance /etc/init.d/glance-${function}
	done

	diropts -m 0750
	dodir /var/run/glance /var/log/nova /var/lock/nova
}
