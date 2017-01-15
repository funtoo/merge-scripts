# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4..5} )

inherit distutils-r1

DESCRIPTION="Python support for the DjVu image format"
HOMEPAGE="http://jwilk.net/software/python-djvulibre"
SRC_URI="https://github.com/jwilk/${PN}/archive/${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"

IUSE="examples doc"

RDEPEND="app-text/djvu"
DEPEND="$RDEPEND
	doc? ( dev-python/sphinx[${PYTHON_USEDEP}] )
	dev-python/cython[${PYTHON_USEDEP}]
	dev-python/setuptools[${PYTHON_USEDEP}]
"

python_compile_all() {
	if use doc; then
		BUILDDIR=doc/_build
		sphinx-build -b html -d "${BUILDDIR}/doctrees" doc/api "${BUILDDIR}/html"
	fi
}

python_install_all() {
	if use doc; then
		rm -fr doc/_build/html/_sources
		local HTML_DOCS=( doc/_build/html/* )
	fi
	distutils-r1_python_install_all
}

src_install() {
	distutils-r1_src_install
	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins "${S}"/examples/*
	fi
}
