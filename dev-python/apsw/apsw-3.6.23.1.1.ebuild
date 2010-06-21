# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/apsw/apsw-3.6.23.1.1.ebuild,v 1.2 2010/06/11 17:36:12 phajdan.jr Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"

inherit distutils eutils versionator

MY_PV="$(replace_version_separator 4 -r)"

DESCRIPTION="APSW - Another Python SQLite Wrapper"
HOMEPAGE="http://code.google.com/p/apsw/"
SRC_URI="http://apsw.googlecode.com/files/${PN}-${MY_PV}.zip"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 ~ppc64 x86"
IUSE=""

RDEPEND=">=dev-db/sqlite-3.6.6.2"
DEPEND="${RDEPEND}
	app-arch/unzip"

S="${WORKDIR}/${PN}-${MY_PV}"

src_prepare() {
	distutils_src_prepare

	epatch "${FILESDIR}/${PN}-3.6.20.1-fix_tests.patch"
}

src_compile() {
	distutils_src_compile --omit=LOAD_EXTENSION
}

src_test() {
	testing() {
		PYTHONPATH="$(ls -d build-${PYTHON_ABI}/lib.*)" "$(PYTHON)" tests.py -v
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install
	dodoc doc/_sources/*
	dohtml -r doc/*
}
