# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="2.[45] 3.*"

inherit git-2 distutils

DESCRIPTIOn="Keystone is a cloud identity service written in Python, which
provides authentication, authorization, and an OpenStack service catalog. It
implements OpenStac's Identity API."
HOMEPAGE="https://launchpad.net/keystone"
EGIT_REPO_URI="https://github.com/openstack/keystone.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~*"
IUSE=""

DEPEND="dev-python/setuptools
		dev-python/pep8
		dev-python/lxml
		dev-python/python-daemon
		!dev-python/keystoneclient"
RDEPEND="${DEPEND}
		 dev-python/python-novaclient
		 dev-python/python-ldap
		 dev-python/passlib"
