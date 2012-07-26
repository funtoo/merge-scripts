# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1

inherit distutils

DESCRIPTION="Anyjson loads whichever is the fastest JSON module installed and provides a uniform API regardless of which JSON implementation is used."
HOMEPAGE="https://bitbucket.org/runeh/anyjson"
SRC_URI="mirror://pypi/${P:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="*"
IUSE=""
