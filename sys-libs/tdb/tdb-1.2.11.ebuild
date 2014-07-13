# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/tdb/tdb-1.2.11.ebuild,v 1.8 2013/09/06 16:04:59 ago Exp $

EAPI=3
PYTHON_DEPEND="python? 2"
RESTRICT_PYTHON_ABIS="3.* *-jython 2.7-pypy-*"

inherit waf-utils python

DESCRIPTION="A simple database API"
HOMEPAGE="http://tdb.samba.org/"
SRC_URI="http://samba.org/ftp/tdb/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm ~hppa ia64 ~mips ~ppc ~ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux"
IUSE="python"

RDEPEND=""
DEPEND="|| ( dev-lang/python:2.7 dev-lang/python:2.6 )
	app-text/docbook-xml-dtd:4.2"

WAF_BINARY="${S}/buildtools/bin/waf"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_configure() {
	local extra_opts=""
	use python || extra_opts+=" --disable-python"
	waf-utils_src_configure \
	${extra_opts}
}

src_test() {
	# the default src_test runs 'make test' and 'make check', letting
	# the tests fail occasionally (reason: unknown)
	emake check || die "emake check failed"
}
