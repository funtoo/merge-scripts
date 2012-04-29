# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="2.[45] 3.* *-jython"

inherit git-2 distutils

DESCRIPTION="Provides services for discovering, registering, and retrieving
virtual machine images. Glance has a RESTful API that allows querying of VM
image metadata as well as retrieval of the actual image."
HOMEPAGE="https://launchpad.net/glance"
EGIT_REPO_URI="https://github.com/openstack/glance.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND="${DEPEND} $(python_abi_depend dev-python/webob dev-python/httplib2 dev-python/routes dev-python/paste dev-python/pastedeploy dev-python/pyxattr dev-python/kombu )"

src_install() {
	distutils_src_install
	newconfd "${FILESDIR}/glance.confd" glance
	newinitd "${FILESDIR}/glance.initd" glance

	for function in api registry scrubber; do
		dosym /etc/init.d/glance /etc/init.d/glance-${function}
	done

	diropts -m 0750
	dodir /var/run/glance /var/log/glance /var/lock/glance

	insinto /etc/glance
	doins ${S}/etc/*
}
