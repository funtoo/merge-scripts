# Distributed under the terms of the GNU General Public License v2

EAPI=5-progress
PYTHON_ABI_TYPE="single"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy"

inherit distutils eutils

DESCRIPTION="Salt is a remote execution and configuration manager."
HOMEPAGE="http://saltstack.org/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="api gnupg keyring ldap libcloud libvirt mako mongodb mysql nova openssl raet redis selinux test timelib +zeromq"

RDEPEND="sys-apps/pciutils
		$(python_abi_depend dev-python/jinja)
		$(python_abi_depend dev-python/markupsafe)
		$(python_abi_depend dev-python/msgpack)
		$(python_abi_depend dev-python/pyyaml)
		$(python_abi_depend dev-python/requests)
		$(python_abi_depend dev-python/setuptools)
		api? ( $(python_abi_depend dev-python/cherrypy) )
		gnupg? ( $(python_abi_depend dev-python/python-gnupg) )
		keyring? ( dev-python/keyring[${PYTHON_USEDEP}] )
		ldap? ( $(python_abi_depend dev-python/python-ldap) )
		libcloud? ( $(python_abi_depend dev-python/libcloud) )
		libvirt? ( dev-python/libvirt-python )
		mako? ( $(python_abi_depend dev-python/mako) )
		mongodb? ( $(python_abi_depend dev-python/pymongo) )
		mysql? ( $(python_abi_depend dev-python/mysql-python) )
		nova? ( >=dev-python/python-novaclient-2.17.0[${PYTHON_USEDEP}] )
		openssl? ( $(python_abi_depend dev-python/pyopenssl) )

		raet? (
		dev-python/libnacl[${PYTHON_USEDEP}]
		dev-python/ioflo[${PYTHON_USEDEP}]
		dev-python/raet[${PYTHON_USEDEP}]
		)

		redis? ( $(python_abi_depend dev-python/redis-py) )
		timelib? ( $(python_abi_depend dev-python/timelib) )
		zeromq? ( $(python_abi_depend dev-python/pyzmq dev-python/m2crypto dev-python/pycrypto) )"

DEPEND="test? ( $(python_abi_depend dev-python/pip dev-python/virtualenv dev-python/timelib) dev-python/SaltTesting ${RDEPEND} )"

PATCHES=(
	"${FILESDIR}/${PN}-2014.7.1-remove-pydsl-includes-test.patch"
	"${FILESDIR}/${PN}-2014.7.5-archive-test.patch"
)

DOCS=(README.rst AUTHORS)

src_prepare() {
	# this test fails because it trys to "pip install distribute"
	rm tests/unit/{modules,states}/zcbuildout_test.py
}

src_install() {
	distutils_src_install

	local s
	for s in minion master syndic; do
		newinitd "${FILESDIR}"/${s}-initd-3 salt-${s}
		newconfd "${FILESDIR}"/${s}-confd-1 salt-${s}
	done

	insinto /etc/${PN}
	doins conf/*
}

src_test() {
	ulimit -n 3072
	SHELL="/bin/bash" TMPDIR=/tmp ./tests/runtests.py --unit-tests --no-report || die
}
