# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy-*"

inherit distutils

RESTRICT="test" # connects to local DB and other nonsense

DESCRIPTION="A Python Object-Document-Mapper for working with MongoDB"
HOMEPAGE="https://github.com/MongoEngine/mongoengine/"
SRC_URI="https://github.com/MongoEngine/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~*"
IUSE="doc"

RDEPEND=""
DEPEND="${RDEPEND} 
		$(python_abi_depend dev-python/setuptools) 
		$(python_abi_depend dev-python/pymongo)
		doc? ( $(python_abi_depend dev-python/sphinx) )"

src_prepare() {
	sed -i -e 's/tests/tests*/g' setup.py || die "Failed to fix test removal thingy"
}

src_compile() {
	distutils_src_compile

	if use doc; then
	   einfo "Generation of documentation"
	  "$(PYTHON -f)" setup.py build_sphinx || die "Generation of documentation failed"
	fi
}

src_install() {
	distutils_src_install
	if use doc; then
		dohtml -r build/sphinx/html/
	fi
}

