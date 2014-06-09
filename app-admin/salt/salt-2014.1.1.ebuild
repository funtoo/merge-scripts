# Distributed under the terms of the GNU General Public License v2

EAPI=5-progress
PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy-*"

inherit distutils eutils

DESCRIPTION="Salt is a remote execution and configuration manager."
HOMEPAGE="http://saltstack.org/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="+jinja ldap +libcloud libvirt mako mongodb mysql openssl redis test timelib"

RDEPEND="$(python_abi_depend dev-python/pyyaml dev-python/msgpack dev-python/pyzmq)
		$(python_abi_depend dev-python/m2crypto dev-python/pycrypto)
		jinja? ( $(python_abi_depend dev-python/jinja) ) 
		ldap? ( $(python_abi_depend dev-python/python-ldap ) )
		libcloud? ( $(python_abi_depend dev-python/libcloud ) )
		libvirt? ( app-emulation/libvirt[python] )
		mako? ( $(python_abi_depend dev-python/mako) )
		mongodb? ( $(python_abi_depend dev-python/pymongo) )
		mysql? ( $(python_abi_depend dev-python/mysql-python) )
		openssl? ( $(python_abi_depend dev-python/pyopenssl) )
		redis? ( $(python_abi_depend dev-python/redis-py) )
		timelib? ( $(python_abi_depend dev-python/timelib) )"

DEPEND="test? ( $(python_abi_depend dev-python/pip dev-python/virtualenv) )
		dev-python/SaltTesting
		${RDEPEND}"

PATCHES=("${FILESDIR}/${PN}-0.17.1-tests-nonroot.patch")
DOCS=(README.rst AUTHORS)

src_prepare() {
	sed -i '/install_requires=/ d' setup.py || die "sed failed"

	# this test fails because it trys to "pip install distribute"
	rm tests/unit/{modules,states}/zcbuildout_test.py
}

src_install() {
	USE_SETUPTOOLS=1 distutils_src_install

	local s
	for s in minion master syndic; do
		newinitd "${FILESDIR}"/${s}-initd-3 salt-${s}
		newconfd "${FILESDIR}"/${s}-confd-1 salt-${s}
	done

	insinto /etc/${PN}
	doins conf/*
}

python_test() {
	ulimit -n 3072
	SHELL="/bin/bash" TMPDIR=/tmp ./tests/runtests.py --unit-tests --no-report || die
}
