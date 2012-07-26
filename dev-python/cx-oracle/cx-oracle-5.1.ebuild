# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"

PYTHON_MULTIPLE_ABIS="1"
PYTHON_MODNAME="cx_Oracle"

inherit distutils

MY_PN=$PYTHON_MODNAME
MY_P=${MY_PN}-${PV}
DESCRIPTION="Python interface to Oracle"
HOMEPAGE="http://www.cxtools.net/default.aspx?nav=cxorlb"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="Computronix"
SLOT="0"
KEYWORDS="*"
IUSE="doc examples"

DEPEND=">=dev-db/oracle-instantclient-basic-10.2.0.3"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${MY_P}

DOCS="README.txt HISTORY.txt"

set_global_options() {
	export ORACLE_HOME="/usr/lib64/oracle/11.2.0.2/client"
}

distutils_src_compile_pre_hook() {
	set_global_options
}

distutils_src_install_pre_hook() {
	set_global_options
}

pkg_postinst() {
	return
	# no python_mod_optimize
}

src_install() {
	distutils_src_install
	if use doc; then
		dohtml -r html/* || die
	fi
	if use examples; then
		docinto examples
		dodoc samples/* || die
	fi
}
