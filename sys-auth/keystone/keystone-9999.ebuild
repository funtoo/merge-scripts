# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="2.[45] 3.* *-jython *-pypy-*"

inherit distutils

if [ "$PV" = "9999" ]; then
	inherit git-2
	EGIT_REPO_URI="https://github.com/openstack/keystone.git"
else
	SRC_URI="http://launchpad.net/${PN}/essex/${PV}/+download/${P}.tar.gz"
fi

DESCRIPTION="Keystone is a cloud identity service written in Python, which
provides authentication, authorization, and an OpenStack service catalog. It
implements OpenStac's Identity API."
HOMEPAGE="https://launchpad.net/keystone"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~*"
IUSE="+doc"

DEPEND="$( python_abi_depend dev-python/setuptools dev-python/pep8 dev-python/lxml dev-python/python-daemon !dev-python/keystoneclient ) doc? ( dev-python/sphinx )"
RDEPEND="${DEPEND} $( python_abi_depend dev-python/python-novaclient dev-python/python-ldap dev-python/passlib )"

src_compile() {
	distutils_src_compile
	if use doc; then
		cd ${S}/doc || die
		make man singlehtml || die
	fi
}

src_install() {
	distutils_src_install
	newconfd "${FILESDIR}/keystone.confd" keystone
	newinitd "${FILESDIR}/keystone.initd" keystone

	diropts -m 0750
	dodir /var/run/keystone /var/log/keystone

	dodoc -r ${S}/etc
	if use doc; then
		doman ${S}/doc/build/man/keystone.1
		dodoc -r ${S}/doc/build/singlehtml
	fi

}

