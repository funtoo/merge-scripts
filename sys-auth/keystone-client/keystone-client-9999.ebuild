# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="2.[45] 3.* *-jython *-pypy-*"

inherit distutils
inherit git-2

EGIT_REPO_URI="https://github.com/openstack/python-keystoneclient"

DESCRIPTION="This is a client for the OpenStack Keystone API. There's a Python API (the keystoneclient module), and a command-line script (keystone). The Keystone 2.0 API is still a moving target, so this module will remain in 'Beta' status until the API is finalized and fully implemented."
HOMEPAGE="$EGIT_REPO_URI"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="+doc"

DEPEND="$( python_abi_depend dev-python/setuptools )"
RDEPEND="${DEPEND} $( python_abi_depend dev-python/httplib2 virtual/python-argparse )"
