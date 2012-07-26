# Distributed under the terms of the GNU General Public License v2

EAPI=4-python
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.*"

inherit distutils

DESCRIPTION="A simple Python library for easily displaying tabular data in a visually appealing ASCII table format."
HOMEPAGE="https://code.google.com/p/prettytable/ http://pypi.python.org/pypi/PrettyTable"
SRC_URI="http://pypi.python.org/packages/source/P/PrettyTable/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

PYTHON_MODNAME="${PN}.py"
