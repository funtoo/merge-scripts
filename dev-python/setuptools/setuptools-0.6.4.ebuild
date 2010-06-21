# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/setuptools/setuptools-0.6.4.ebuild,v 1.10 2009/11/21 03:13:00 arfrever Exp $

EAPI="2"
SUPPORT_PYTHON_ABIS="1"

inherit distutils eutils

MY_PN="distribute"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Distribute (fork of Setuptools) is a collection of extensions to Distutils"
HOMEPAGE="http://pypi.python.org/pypi/distribute"
SRC_URI="http://pypi.python.org/packages/source/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="PSF-2.2"
SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ~ia64 ~mips ppc ~ppc64 ~s390 ~sh ~sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

DEPEND=""
RDEPEND=""

S="${WORKDIR}/${MY_P}"

PYTHON_MODNAME="easy_install.py pkg_resources.py setuptools site.py"
DOCS="README.txt docs/easy_install.txt docs/pkg_resources.txt docs/setuptools.txt"

src_prepare() {
	distutils_src_prepare

	epatch "${FILESDIR}/${PN}-0.6_rc7-noexe.patch"

	# Remove tests that access the network (bugs #198312, #191117)
	rm setuptools/tests/test_packageindex.py

	sed -e "/def _being_installed():/a \\    return False" -i setup.py || die "sed setup.py failed"
}

src_test() {
	tests() {
		PYTHONPATH="." "$(PYTHON)" setup.py test
	}
	python_execute_function tests
}

pkg_preinst() {
	# Delete unneeded files which cause problems. These files were created by some older, broken versions.
	if has_version "<dev-python/setuptools-0.6.3-r2"; then
		rm -fr "${ROOT}"usr/lib*/python*/site-packages/{,._cfg????_}setuptools-*egg-info* || die "Deletion of broken files failed"
	fi
}
