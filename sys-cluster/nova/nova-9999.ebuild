# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_RESTRICTED_ABIS="2.[45] 3.* *-jython *-pypy-*"
PYTHON_MULTIPLE_ABIS="1"

inherit git-2 distutils

DESCRIPTION="Nova is a cloud computing fabric controller (the main part of an IaaS system). It is written in Python."
HOMEPAGE="https://launchpad.net/nova"
EGIT_REPO_URI="https://github.com/openstack/nova.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="+controller +kvm"

DEPEND="$(python_abi_depend dev-python/setuptools dev-python/lockfile dev-python/netaddr dev-python/eventlet dev-python/python-gflags dev-python/nosexcover dev-python/sqlalchemy-migrate dev-python/pylint dev-python/mox dev-python/pep8 dev-python/cheetah dev-python/carrot dev-python/lxml dev-python/python-daemon dev-python/wsgiref dev-python/sphinx dev-python/suds dev-python/paramiko dev-python/feedparser)"
RDEPEND="${DEPEND} $(python_abi_depend dev-python/iso8601 dev-python/m2crypto dev-python/python-novaclient dev-python/nova-adminclient dev-python/boto dev-python/prettytable sys-cluster/glance ) controller? ( net-misc/rabbitmq-server ) app-admin/sudo net-firewall/iptables kvm? ( app-emulation/libvirt[qemu] ) virtual/logger sys-fs/lvm2"

src_install() {
	distutils_src_install
	newconfd "${FILESDIR}/nova.confd" nova
	newinitd "${FILESDIR}/nova.initd" nova

	for function in api compute network objectstore scheduler volume xvpvncproxy; do
		dosym /etc/init.d/nova /etc/init.d/nova-${function}
	done

	diropts -m 0750
	dodir /var/run/nova /var/lib/nova /var/log/nova /var/lock/nova /etc/nova

	# documentation
	# api-paste config and others:
	docinto etc
	dodoc ${S}/etc/nova/*
	# restructuredtext docs:
	docinto rst
	dodoc -r ${S}/doc/source/*

}
