# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy-*"

inherit distutils

DESCRIPTION="DB-API 2.0 interface for SQLite 3.x"
HOMEPAGE="http://code.google.com/p/pysqlite/ https://pypi.python.org/pypi/pysqlite"
SRC_URI="https://pypi.python.org/packages/source/p/pysqlite/${P}.tar.gz"

LICENSE="pysqlite"
SLOT="2"
KEYWORDS="*"
IUSE="examples"

DEPEND=">=dev-db/sqlite-3.3.8:3"
RDEPEND=${DEPEND}

PYTHON_CFLAGS=("2.* + -fno-strict-aliasing")

PYTHON_MODULES="pysqlite2"

src_prepare() {
	distutils_src_prepare

	# Enable support for loadable sqlite extensions.
	sed -e "/define=SQLITE_OMIT_LOAD_EXTENSION/d" -i setup.cfg || die "sed setup.cfg failed"

	# Fix encoding.
	sed -e "s/\(coding: \)ISO-8859-1/\1utf-8/" -i lib/{__init__.py,dbapi2.py} || die "sed lib/{__init__.py,dbapi2.py} failed"

	# Workaround to make tests work without installing them.
	sed -e "s/pysqlite2.test/test/" -i lib/test/__init__.py || die "sed lib/test/__init__.py failed"
}

src_test() {
	cd lib

	testing() {
		python_execute PYTHONPATH="$(ls -d ../build-${PYTHON_ABI}/lib.*)" "$(PYTHON)" -c "from test import test; import sys; sys.exit(test())"
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	rm -fr "${ED}usr/pysqlite2-doc"

	delete_tests() {
		rm -fr "${ED}$(python_get_sitedir)/pysqlite2/test"
	}
	python_execute_function -q delete_tests

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins doc/includes/sqlite3/*
	fi
}
