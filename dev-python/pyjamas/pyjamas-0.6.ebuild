# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

PYTHON_DEPEND="2"

inherit distutils python

HOMEPAGE="http://pyjs.org"

# Mmm...
if [ $PV = "9999" ]; then
	inherit subversion
	ESVN_REPO_URI="https://${PN}.svn.sourceforge.net/svnroot/${PN}/trunk"
elif [ $PV = "0.6.9999" ]; then
	inherit subversion
	ESVN_REPO_URI="https://${PN}.svn.sourceforge.net/svnroot/${PN}/tags/release_0_6"
else
	SRC_URI="mirror://sourceforge/${PN}/${PV}/${P}.tgz"
	KEYWORDS="~x86"
fi

DESCRIPTION="Stand-alone python to javascript compiler"
LICENSE="Apache-2.0"
SLOT="0"
IUSE="doc"

DEPEND=""
RDEPEND="${DEPEND}"

src_compile() {
	cd ${S}
	python2 bootstrap.py /usr/share/${PN} # QA: call to py2, hard-coded path
	mv run_bootstrap_first_then_setup.py setup.py
	distutils_src_compile
	sed -i -e's/..\/..\/bin\///' examples/*/build.sh # QA: sed call
}

src_install() {
	# QA: does this ensure placement in /u/l/python2.X/site-packages
	distutils_src_install

	dobin bin/pyjsbuild bin/pyjscompile

	if [ $PV = "9999" ] || [ $PV = "0.7" ]; then
		doman pyjs/src/pyjs/pyjsbuild.1
	elif [ $PV = "0.6" ] || [ $PV = "0.6.9999" ]; then
		doman debian/pyjsbuild.1
	fi

	dodoc CHANGELOG
	use doc && dohtml -r doc/*
}

pkg_postinst() {
	PYTHON_MODNAME="pyjd" distutils_pkg_postinst
	PYTHON_MODNAME="pyjs" distutils_pkg_postinst
}

