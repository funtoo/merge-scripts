# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit distutils

MY_PN=cx_Oracle
MY_P=${MY_PN}-${PV}
DESCRIPTION="Python interface to Oracle"
HOMEPAGE="http://www.cxtools.net/default.aspx?nav=cxorlb"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="Computronix"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc examples"

DEPEND=">=dev-db/oracle-instantclient-basic-10.2.0.3"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${MY_P}

DOCS="README.txt HISTORY.txt"

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
