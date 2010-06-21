# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/apsw/apsw-3.6.6.2.1.ebuild,v 1.1 2008/12/13 11:21:40 mrness Exp $

inherit distutils versionator

MY_PV=$(replace_version_separator 3 -r)

DESCRIPTION="APSW - Another Python SQLite Wrapper"
HOMEPAGE="http://code.google.com/p/apsw/"
SRC_URI="http://apsw.googlecode.com/files/${PN}-${MY_PV}.zip"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 ~ppc64 ~x86"
IUSE=""

RDEPEND="dev-lang/python >=dev-db/sqlite-3.6.11"
DEPEND="app-arch/unzip ${RDEPEND}"

S="${WORKDIR}/${PN}-${MY_PV}"

src_compile() {
	distutils_src_compile --omit=LOAD_EXTENSION
}

src_install() {
	distutils_src_install
	dodoc doc/_sources/*
	dohtml -r doc/*
}

src_test() {
	PYTHONPATH="$(ls -d build/lib.*)" "${python}" tests.py || die "tests failed"
}
