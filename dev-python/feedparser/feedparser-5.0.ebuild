# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/feedparser/feedparser-4.2_pre316.ebuild,v 1.1 2010/11/25 15:15:10 sping Exp $

EAPI="2"

PYTHON_DEPEND="*:2.4"
SUPPORT_PYTHON_ABIS="1"

inherit distutils

DESCRIPTION="Parse RSS and Atom feeds in Python"
HOMEPAGE="http://www.feedparser.org/"
SRC_URI="http://feedparser.googlecode.com/files/feedparser-5.0.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~x86-solaris"
IUSE=""

DEPEND=""
RDEPEND=">=dev-python/sgmllib-1.0"

PYTHON_MODNAME="feedparser.py"
DOCS="LICENSE"
DISTUTILS_USE_SEPARATE_SOURCE_DIRECTORIES="1"

src_prepare() {
	python_copy_sources
	tweak() {
		[ "${PYTHON_ABI%%.*}" != "3" ] && return
		2to3 -w feedparser/feedparser.py feedparser/feedparsertest.py || die "2to3 fail"
		2to3 -w setup.py || die "2to3 fail"
	}
	python_execute_function --action-message 'Conditonally running 2to3' -s tweak
}

src_compile() {
	distutils_src_compile
}

src_install() {
	distutils_src_install
	insinto /usr/share/doc/${PF}
	doins README* || die
}
